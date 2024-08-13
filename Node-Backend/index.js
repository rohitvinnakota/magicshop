const express = require('express');
const app = express();
const stripe = require('stripe')('YOUR_STRIPE_SK_KEY_HERE');
const AWS = require("aws-sdk");
const { ConsoleLogger } = require('amazon-ivs-chat-messaging');
require('dotenv').config()
const dynamodb = new AWS.DynamoDB.DocumentClient();


const USER_CAPABILITIES = ['SEND_MESSAGE']

app.get('/', (req, res) => {
    res.send('Hello, world!');
});

app.post('/paymentSheet', async (req, res) => {
    try {
        const customerId = req.header('customerId')
        const paymentAmount = req.header('paymentAmount')
        if (!customerId || !paymentAmount) {
            throw new Error('Required headers are missing')
        }
        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: '2022-11-15' }
        );
        // ADD A TRANSFER GROUP HERE TO SPLIT COSTS
        const paymentIntent = await stripe.paymentIntents.create({
            amount: paymentAmount,
            currency: 'cad',
            customer: customerId,
            automatic_payment_methods: {
                enabled: true,
            },
            application_fee_amount: Math.floor(paymentAmount * 0.08), // your margin as a marketplace. Must be an INT
            transfer_data: {
                destination: req.header('accountId'),
            },
        });

        res.json({
            paymentIntent: paymentIntent.client_secret,
            ephemeralKey: ephemeralKey.secret,
            customer: customerId,
            publishableKey: 'YOUR_PK_HERE'
        });
    } catch (error) {
        console.error(error)
        res.status(500).json({ error: 'Something went wrong' })
    }
});

function flattenObject(obj, prefix = '') {
    return Object.keys(obj).reduce((acc, key) => {
        const propName = prefix ? `${prefix}.${key}` : key;
        const propValue = obj[key];

        if (typeof propValue === 'object' && propValue !== null) {
            const flattened = flattenObject(propValue, propName);
            acc = { ...acc, ...flattened };
        } else {
            acc[propName] = propValue;
        }

        return acc;
    }, {});
}

app.get('/prices', async (req, res) => {
    try {
        const prices = await stripe.prices.list(
            { expand: ['data.product'] },
            { stripeAccount: req.header('accountId') }
        );

        const flattenedPrices = prices.data.map(price => {
            const flattenedPrice = flattenObject(price);
            return {
                ...flattenedPrice,
                product_id: price.product.id,
                product_name: price.product.name,
                product_description: price.product.description
            };
        });

        res.json({ prices: flattenedPrices });
    } catch (err) {
        console.error(err);
        res.status(500).send('Internal Server Error');
    }
});


app.post('/createCustomer', async (req, res) => {
    try {
        const customerAmplifyUserId = req.header('customerAmplifyUserId');
        const customerEmail = req.header('customerEmail');

        const customer = await stripe.customers.create({
            metadata: { customerAmplifyUserId: customerAmplifyUserId },
            email: customerEmail
        });
        res.json({ customer: customer });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Something went wrong!' });
    }
});

app.post('/searchCustomer', async (req, res) => {
    try {
      const customerAmplifyUserId = req.header('customerAmplifyUserId')
      const customer = await stripe.customers.search({
          query: `metadata["customerAmplifyUserId"]: "${customerAmplifyUserId}"`
      });
      const customerData = {
        id: customer.data[0].id,
        shipping: customer.data[0].shipping,
      };
      res.json({ customer: customerData });
    } catch (error) {
      console.error(error);
      res.status(500).send('Internal Server Error');
    }
});


app.post('/updateCustomerShippingInfo', async (req, res) => {
    try {
        // Get the customer ID from the request header
        const customerStripeId = req.header('customerStripeId');
        // Get the shipping information from the request headers
        const shipping = {
            name: req.header('customerFullName'),
            address: {
                line1: req.header('shippingAddressLine1'),
                line2: req.header('shippingAddressLine2'),
                city: req.header('shippingAddressCity'),
                state: req.header('shippingAddressState'),
                postal_code: req.header('shippingAddressPostalCode'),
                country: req.header('shippingAddressCountry')
            }
        };
        // Update the customer's shipping information
        const customer = await stripe.customers.update(customerStripeId, {
            shipping: shipping,
        });

        res.json({ customer: customer });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/createChatToken', async (req, res) => {
    // Construct parameters.
    // Documentation is available at https://docs.aws.amazon.com/ivs/latest/ChatAPIReference/Welcome.html
    const ivs = new AWS.Ivschat();
    const capabilities = req.header('capabilities') == 'user' ? USER_CAPABILITIES : []
    const params = {
        roomIdentifier: req.header('roomId'), // chat room ARN
        userId: req.header('userId'), // Application provided
        capabilities: capabilities,
        sessionDurationInMinutes: 180,
    };
    try {
        const data = await ivs.createChatToken(params).promise();
        console.info("Got data:", data);
        res.status(200).json({
            sessionExpirationTime: data.sessionExpirationTime,
            token: data.token,
            tokenExpirationTime: data.tokenExpirationTime
        });
    } catch (err) {
        console.error('ERROR: chatAuthHandler > IVSChat.createChatToken:', err);
        res.status(500).json({
            error: err
        });
    }
});

app.get('/broadcastInfo', async (req, res) => {
    try {
        // Extract userId from the request header
        const userId = req.header('userId');
        if (!userId) {
            return res.status(400).send('userId is required');
        }

        // Fetch seller's data
        const sellerData = await getSellerData(userId);
        if (!sellerData) {
            return res.status(404).send('Seller not found');
        }

        // Fetch stream info using the seller's id
        const streamInfo = await getStreamInfo(sellerData.id);

        // Combine and send the results
        res.json({ sellerData, streamInfo });
    } catch (error) {
        // Handle any errors
        res.status(500).send(error.message);
    }
});

app.get('/stripeAccountId', async (req, res) => {
    try {
        // Extract userId from the request header
        const channelArn = req.header('channelArn');
        if (!channelArn) {
            return res.status(400).send('channelArn is required');
        }

        const params = {
            TableName: 'StreamInfo-b4mj2sczfrfurcbkjzhumreg74-dev',
            FilterExpression: 'channelArn = :channelArn',
            ExpressionAttributeValues: {
                ':channelArn': channelArn
            }
        };

        const result = await dynamodb.scan(params).promise();
        const stripeConnectAccountId = result.Items.length > 0 ? result.Items[0]['stripeConnectAccountId'] : null;
        // Combine and send the results
        res.json({ stripeConnectAccountId: stripeConnectAccountId });
    } catch (error) {
        // Handle any errors
        res.status(500).send(error.message);
    }
});


async function getSellerData(userId) {
    const params = {
        TableName: 'Sellers-b4mj2sczfrfurcbkjzhumreg74-dev',
        FilterExpression: 'sellersSellerUserId = :userId',
        ExpressionAttributeValues: {
            ':userId': userId
        }
    };

    const result = await dynamodb.scan(params).promise();
    // Since scan returns all items that match the filter, you should ensure you are getting the expected results.
    return result.Items.length > 0 ? result.Items[0] : null;
}


async function getStreamInfo(id) {
    const params = {
        TableName: 'StreamInfo-b4mj2sczfrfurcbkjzhumreg74-dev',
        FilterExpression: 'SellerId = :id',
        ExpressionAttributeValues: {
            ':id': id
        },
        ProjectionExpression: 'awsIVSIngestServer, awsIVSPlaybackURL, awsIVSStreamKey, chatRoomArn'
    };
    const result = await dynamodb.scan(params).promise();
    return result.Items.length > 0 ? result.Items[0] : null;
}

const port = process.env.PORT || 3000;
app.listen(port, () =>
  console.log(`Server is listening on port ${port}.`)
);
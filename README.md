# ✨ magicshop ✨ 
Starter template for building apps of the future.

The original intention of this project was to build a livestream e-commerce application similar to Alibaba Live or Whatnot. It supports setup of concurrent livestreams, each with 1 click purchasing enabled from within the stream. However, with a few clever additions, this can be easily extended to other use cases such as: 

- A live performace app for artists
- A live auction app
- A TikTok like shopping experience where livestreams are replaced by static videos
- An AI NPC portal to allow interactions with digital VTubers, etc.

Magicshop provides the following

- A starter UI that supports a "feed" of streams 
- Live streaming from the app and a live chat interface for each stream 
- A Stripe Connect integration to process payments directly from each stream
- An out-of-the-box implementation of a sign-up/login flow that supports Sign in With Apple
- Various little features that support a smooth flow between different services that power the app(more below)

### 📜 Setup 📜

- Magicshop relies on a few key services. AWS IVS, AWS Amplify, and Stripe Connect
- You will need a Stripe account with stripe connect setup. Paste your stripe PK in the `stripePublishableKey` portion of your Info.plist file.
  Also paste your stripe SK in `index.js` on line 3. Strongly consider doing something more secure in a live environment
- Update the `/paymentSheet` route in `index.js` to read your stripe PK
- You will need an AWS account, the AWS CLI tool, and Amplify [installed](https://aws.amazon.com/getting-started/hands-on/build-ios-app-amplify/module-two/) on your machine
- You will need AWS IVS setup, including having an [IAM user with the proper permissions](https://docs.aws.amazon.com/ivs/latest/LowLatencyUserGuide/getting-started.html)

- You will need to generate Amplify config files before running the app. If you are setting the project up for the first time, from the magicshop folder run 

`amplify init` and choose an `ios App` as your app type. 

- You will also need to setup a Data model. Here is a starter schema that can be modified as necesscary 

```type StreamPreviewInfoV0 @model @auth(rules: [{allow: public}]) {
  id: ID!
  streamName: String
  channelArn: String
  s3StreamPreviewURL: String
  chatRoomArn: String!
}

type LivestreamCache @model @auth(rules: [{allow: public}]) {
  id: ID!
  liveStreams: String
}

type StreamInfo @model @auth(rules: [{allow: public}]) {
  id: ID!
  awsIVSIngestServer: String
  awsIVSStreamKey: String
  awsIVSPlaybackURL: String
  channelArn: String
  SellerStream: Sellers @hasOne
  SellerId: String
  stripeConnectAccountId: String
  chatRoomArn: String
}

type Buyers @model @auth(rules: [{allow: public}]) {
  id: ID!
  BuyerUser: Users @hasOne
}

type Sellers @model @auth(rules: [{allow: public}]) {
  id: ID!
  SellerUser: Users @hasOne
}

type Users @model @auth(rules: [{allow: public}]) {
  id: ID!
  userEmail: String
  userName: String
}``` 

- You will need to ensure your backend is running first. From the Node-Backend dir, run `npm install && npm start`

- Run `pod install` from the magicshop folder

- Then open a simulator in XCode and you should be able to run the base version of magicshop!


### 🧱 Future improvements 🧱

- Please follow best security practices if you are running this on a live server. This includes secure endpoints, non-hardcoded keys, etc.
- There are a few manual processes(such as seller onboarding) that take place outside the app. There is potential for these to be automated down the road.
- Ensure you are regularly updating expirys on your IAM users and keys, as this is a common issue.

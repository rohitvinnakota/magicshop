# magicshop
Starter template for building apps of the future.

The original intention of this project was to build a livestream e-commerce application similar to Alibaba Live or Whatnot. It supports setup of concurrent livestreams, each with 1 click purchasing enabled from within the stream. However, with a few clever additions, this can be easily extended to other use cases such as: 

- A live performace app for artists
- A live auction app
- An AI NPC portal to allow interactions with digital VTubers, etc.

Magicshop provides the following 

- A starter UI that supports a "feed" of streams 
- Live streaming from the app and a live chat interface for each stream 
- A Stripe Connect integration to process payments directly from each stream
- Various little features that support a smooth flow between different services that power the app(more below).  

### Setup

- Magicshop relies on a few key services. AWS IVS, AWS Amplify, and Stripe Connect. 

- You will need an AWS account, the AWS CLI tool, and Amplify [installed](https://aws.amazon.com/getting-started/hands-on/build-ios-app-amplify/module-two/) on your machine
- You will need AWS IVS setup, including having an [IAM user with the proper permissions](https://docs.aws.amazon.com/ivs/latest/LowLatencyUserGuide/getting-started.html)

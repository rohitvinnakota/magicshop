import SwiftUI
import Kingfisher

struct MarketView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var feedManager: FeedManager
    @State private var isEULAAccepted = UserDefaultsManager.shared.getIsEULAAccepted()
    @State private var blockedStreams = UserDefaultsManager.shared.getBlockedStreams()

    var body: some View {
        if !isEULAAccepted {
            ScrollView {
                Text(eulaText)
                    .padding()
                Button(action: {
                    UserDefaultsManager.shared.setEULAAccepted()
                    isEULAAccepted = true
                }) {
                    Text("I Accept")
                        .foregroundColor(Color.white)
                        .font(Font.custom("Avenir", size: 18))
                        .frame(width: 200, height: 50)
                        .background(Color.purple) // Replace with your desired background color
                        .cornerRadius(5)
                }
                .padding()
            }
            .toolbar(.hidden, for: .tabBar)
        } else {
            NavigationView {
                VStack {
                    ScrollView {
                        Text("magicshop")
                            .foregroundColor(Constants.crayolaRedColor)
                            .font(Font.custom("Avenir", size: 30))
                        let filteredStreams = feedManager.liveStreams?.filter { !blockedStreams.contains($0.stream.channelArn) } ?? []
                        if filteredStreams.isEmpty {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title)
                                .foregroundColor(Color.gray)
                            Text("No streams found. Pull down to refresh.")
                                .font(Font.custom("Avenir", size: 14))
                                .foregroundColor(Constants.silverCreamColor)
                                .scaledToFit()
                                .padding(3)
                        } else {
                            ForEach(filteredStreams, id: \.id) { streamFeedInfo in
                                if streamFeedInfo.id == "arn:aws:ivs:us-east-1:008406561616:channel/test2" {
                                    NavigationLink {
                                        PlaybackView(channelArn: streamFeedInfo.stream.channelArn, chatRoomArn: streamFeedInfo.streamChatRoomArn)
                                    } label: {
                                        StreamCard(streamFeedInfo: streamFeedInfo)
                                            .frame(maxWidth: .infinity)
                                            .listRowInsets(EdgeInsets())
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .navigationBarHidden(true)
            }
            .colorScheme(.dark)
            .refreshable {
                feedManager.getLivestreamStreamSessions()
            }
            .onAppear {
                feedManager.getLivestreamStreamSessions()
                UserDefaultsManager.shared.setBlockedStreams([])
            }
            .padding(.top, 10)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct StreamCard: View {
    @Environment(\.colorScheme) var colorScheme
    let streamFeedInfo: StreamFeedInfo
    var body: some View {
        VStack {
                KFImage(URL(string: streamFeedInfo.streamPictureUrl))
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .frame(width: UIScreen.main.bounds.width * 0.98, height: UIScreen.main.bounds.height * 0.3)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .scaledToFill()
                    .listRowInsets(EdgeInsets())
                Text(streamFeedInfo.streamName)
                    .lineLimit(2)
                    .font(.custom("Avenir", size: 24))
                    .foregroundColor(Constants.silverCreamColor)
                HStack {
                    Text("\(streamFeedInfo.stream.viewerCount)")
                        .foregroundColor(Constants.crayolaRedColor)
                    Image(systemName: "person.fill")
                        .foregroundColor(Constants.crayolaRedColor)
                }
                .padding(.bottom, 20)
        }
        .background(Color.black)
        .frame(maxWidth: .infinity)
    }
}

struct GlowModifier: ViewModifier {
    @State private var isGlowing = false
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    content
                        .foregroundColor(Constants.crayolaRedColor)
                        .blur(radius: 10)
                        .opacity(isGlowing ? 0.8 : 0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                }
            )
            .onAppear {
                isGlowing = true
            }
    }
}

let eulaText: LocalizedStringKey = """
**MAGICSHOP MARKETPLACE END-USER LICENSE AGREEMENT (EULA)**

IMPORTANT: PLEASE READ THIS AGREEMENT CAREFULLY BEFORE USING THE MAGICSHOP APP.

BY INSTALLING, ACCESSING, OR OTHERWISE USING THE APP, YOU AGREE TO BE BOUND BY THE TERMS OF THIS AGREEMENT.
IF YOU DO NOT AGREE TO THE TERMS OF THIS AGREEMENT, DO NOT INSTALL OR USE THE APP.

**1. License Grant**

Subject to the terms and conditions of this Agreement, Licensor grants the Licensee a non-exclusive, non-transferable,
and revocable license to use the App for personal or business use, solely in accordance with the App's documentation.

**2. Restrictions**

Licensee shall not:
a. Modify, adapt, translate, reverse engineer, decompile, disassemble, or create derivative works based on the App;
b. Remove or alter any proprietary notices, labels, or marks on the App;
c. Use the App for any purpose that is illegal or prohibited by applicable law;
d. Post, transmit, or promote any content that is harmful, abusive, harassing, objectionable, defamatory, or violates the rights of others.

**3. Content Moderation and User Behavior**

a. Licensor employs content moderation mechanisms to prevent and remove harmful, abusive, or objectionable content on the App.
b. Licensor maintains a strict no-tolerance policy for users engaging in abusive behavior, harassment, or posting objectionable content.
c. Users found in violation of this policy may have their access to the App restricted or terminated at Licensor's sole discretion.

**4. Ownership**

Licensee acknowledges and agrees that Licensor retains all right, title, and interest in and to the App, including all copyrights,
trademarks, and other intellectual property rights associated with the App. This Agreement does not grant Licensee any rights
to use Licensor's trademarks, trade names, or other designations.

**5. Support and Updates**

Licensor may, at its sole discretion, provide updates, maintenance, or support services for the App. Such services may be subject
to additional terms and fees.

**6. Termination**

This Agreement is effective until terminated. Licensee may terminate this Agreement at any time by uninstalling and destroying
all copies of the App. Licensor may terminate this Agreement immediately and without notice if Licensee breaches any provision of this Agreement.
Upon termination, Licensee must cease all use of the App and destroy all copies of the App in Licensee's possession.

**7. Disclaimer of Warranty**

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NONINFRINGEMENT. LICENSOR DOES NOT WARRANT THAT THE APP WILL BE ERROR-FREE OR UNINTERRUPTED.

**8. Limitation of Liability**

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL LICENSOR BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL
DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF DATA, OR ANY OTHER PECUNIARY LOSS)
ARISING OUT OF THE USE OF OR INABILITY TO USE THE APP, EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

**9. Governing Law**

This Agreement shall be governed by and construed in accordance with the laws of Ontario, Canada, without regard to its conflict of law principles.

**10. Entire Agreement**

This Agreement constitutes the entire agreement between the parties with respect to the App and supersedes all prior or contemporaneous understandings,
agreements, representations, and warranties, whether oral or written.

**11. Contact Information**

If you have any questions or concerns about this Agreement or encounter harmful or objectionable content on the App, please contact admin@magicshophq.com

By installing or using the App, the Licensee acknowledges that they have read, understood, and agree to be bound by the terms and conditions of this Agreement.

Magicshop Inc.
September 28, 2023
"""

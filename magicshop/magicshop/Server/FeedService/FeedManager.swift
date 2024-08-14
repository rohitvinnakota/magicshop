import Amplify
import SwiftUI
import Kingfisher

class FeedManager: ObservableObject {
    @Published var liveStreams: [StreamFeedInfo]?
    @Published var imageCache = NSCache<NSString, UIImage>()

    /**
     Returns a JSON object containing information about currentlivestreams.
     Each stream object has the following properties:
     "channelArn": This is the Amazon Resource Name (ARN) of the channel on which the stream is being broadcast.
     "health": This indicates the health of the stream. The value "HEALTHY" indicates that the stream is functioning normally.
     "startTime": This is the time at which the stream started. It is a string in ISO-8601 format
     "state": This indicates the current state of the stream. The value "LIVE" indicates that the stream is currently being broadcast.
     "streamId": This is a unique identifier for the stream.
     "viewerCount": This is the number of viewers currently watching the stream.
     */
    func getLivestreamStreamSessions() {
        Amplify.API.query(request: .get(LivestreamCache.self, byId: "main_cache")) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let cacheInfo):
                    DispatchQueue.main.async {
                        self.getStreamInfoJSONDecoded(livestreamJson: cacheInfo!.liveStreams!)
                    }
                case .failure(let error):
                    print("Get failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Get failed event with error \(error)")
            }
        }
    }

    /**
     * Decodes a JSON string into a dictionary of streams.
     *
     * - Parameters:
     *   - livestreamJson: The JSON string to be decoded.
     *
     * - Returns:
     *   An array of Streams objects, or nil if the JSON string could not be decoded.
     */
    func getStreamInfoJSONDecoded(livestreamJson: String) {
        let decoder = JSONDecoder()
        if let data = livestreamJson.data(using: .utf8) {
            do {
                let response = try decoder.decode([String: [StreamAPIInfo]].self, from: data)
                let streamResposne: [StreamAPIInfo] = response["streams"]!
                // swiftlint:disable force_cast
                if !response.isEmpty {
                    getStreamPreviewInfo(streamAPIInfoList: streamResposne)
                }
                // Use the streams array here
            } catch {
                print(error)
            }
        }
    }

    /**
     * Queries the server for information to show on the market feed for current livestreams
     *
     * - Parameters:
     *   - streamAPIInfoList: A list of StreamAPIInfo objects.
     */
    func getStreamPreviewInfo(streamAPIInfoList: [StreamAPIInfo]) {
        // Create a predicate that filters StreamPreviewInfoV0 objects based on whether
        // their channelArn field is contained in the provided list of channelArns.
        // StreamPreviewInfo contains feed information for ALL sellers, regardless of thier
        // livestream status, so we query it to only get info for the sellers who are currently
        // live
        let previewKeys = StreamPreviewInfoV0.keys
        let channelArns = streamAPIInfoList.map { $0.channelArn } as! [String]
        let predicate = channelArns.contains(previewKeys.channelArn.rawValue)
        Amplify.API.query(request: .paginatedList(
            StreamPreviewInfoV0.self, where: (predicate as? QueryPredicate), limit: 100)) { event in
                switch event {
                case .success(let result):
                    switch result {
                    case .success(let streamPreviewInfo):
                        DispatchQueue.main.async {
                            self.setStreamFeedInfo(streamAPIInfoList: streamAPIInfoList, streamPreviewInfoList: streamPreviewInfo.elements)
                        }
                    case .failure(let error):
                        print("getStreamPreviewInfo failed result with \(error.errorDescription)")
                    }
                case .failure(let error):
                    print("getStreamPreviewInfo failed event with error \(error)")
                }
        }
    }

    func setStreamFeedInfo(streamAPIInfoList: [StreamAPIInfo], streamPreviewInfoList: [StreamPreviewInfoV0]) {
        let streamDict = Dictionary(uniqueKeysWithValues: streamPreviewInfoList.map { ($0.channelArn, $0) })
        // Use map to transform the list of StreamAPIInfo objects into a list of StreamFeedInfo objects
        let combinedStreamFeedInfo = streamAPIInfoList.map { StreamFeedInfo(
            stream: $0,
            streamName: streamDict[$0.channelArn]?.streamName ?? "",
            streamPictureUrl: streamDict[$0.channelArn]?.s3StreamPreviewURL ?? "",
            streamChatRoomArn: streamDict[$0.channelArn]?.chatRoomArn ?? ""
            )
        }
        self.liveStreams = combinedStreamFeedInfo
    }
}

// Struct to represent the response from the AWS IVS SDK that represents current livestreams
struct StreamAPIInfo: Codable, Hashable, Identifiable {
    var id: String { channelArn }
    let channelArn: String
    let health: String
    let startTime: String
    let state: String
    let streamId: String
    let viewerCount: Int
}

struct StreamFeedInfo: Codable, Hashable, Identifiable {
    var id: String { stream.channelArn }
    let stream: StreamAPIInfo
    let streamName: String
    let streamPictureUrl: String
    let streamChatRoomArn: String
}

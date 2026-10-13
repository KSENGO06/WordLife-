//
//  LifeWordWidgetLiveActivity.swift
//  LifeWordWidget
//
//  Created by Oksana on 12.10.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LifeWordWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LifeWordWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LifeWordWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LifeWordWidgetAttributes {
    fileprivate static var preview: LifeWordWidgetAttributes {
        LifeWordWidgetAttributes(name: "World")
    }
}

extension LifeWordWidgetAttributes.ContentState {
    fileprivate static var smiley: LifeWordWidgetAttributes.ContentState {
        LifeWordWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LifeWordWidgetAttributes.ContentState {
         LifeWordWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LifeWordWidgetAttributes.preview) {
   LifeWordWidgetLiveActivity()
} contentStates: {
    LifeWordWidgetAttributes.ContentState.smiley
    LifeWordWidgetAttributes.ContentState.starEyes
}

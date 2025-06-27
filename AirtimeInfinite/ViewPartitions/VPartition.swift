//
//  VPartition.swift
//
//  Created by Kieran Brown on 10/26/19.
//

import Foundation
import SwiftUI

/// # Vertical Partition
///
/// Used to create resizable views that share a total height,
/// Takes 3 generic arguments to prevent users from needing to wrap content views within an  `AnyView`
///
///   - note
///   the syntax looks something like this, So if closures are still kind of new to you just think that you are sending a letter(`View`) to somebody  and it needs an Envelope(`{}`) to get there.
///
///   ```
///   VPart(top: {
///       Rectangle()
///   }, bottom: {
///       Circle()
///  }) {
///     Capsule()
///  }
///  ```
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct VPart<Top, Bottom, Handle> where Top: View, Bottom: View, Handle: View {
    public var top: Top
    public var bottom: Bottom
    public var handle: Handle
    
    /// Amount of time it takes before a gesture is recognized as a longPress, the precursor to the drag.
    var minimumLongPressDuration = 0.05
    var handleSize: CGSize = CGSize(width: 75, height: 15)
    
    public var pctSplit: CGFloat = 0.5
    var paddingFactor: CGFloat = 1
    
    // To optionally disable animations (e.g. on rotation)
    var disableAnimations: Bool = false
    
    // dragState and viewState are also taken directly from Apples "Composing SwiftUI Gestures"
    @GestureState var dragState = DragState.inactive
    @State var viewState = CGSize.zero
    
    // A bit of a convienence so I dont have to write this again and again.
    var currentOffset: CGFloat {
        viewState.height + dragState.translation.height
    }
    
    /// Creates the `Handle` and adds the drag gesture to it.
    func generateHandle() -> some View {
        
        // This gesture sequence is also directly from apples "Composing SwiftUI Gestures"
        let longPressDrag = LongPressGesture(minimumDuration: minimumLongPressDuration)
            .sequenced(before: DragGesture())
            .updating($dragState) { value, state, transaction in
                switch value {
                // Long press begins.
                case .first(true):
                    state = .pressing
                // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                }
        }
        .onEnded { value in
            guard case .second(true, let drag?) = value else { return }
            if disableAnimations {
                self.viewState.height += drag.translation.height
                self.viewState.width += drag.translation.width
            } else {
                withAnimation(.linear(duration: 0.2)) {
                    self.viewState.height += drag.translation.height
                    self.viewState.width += drag.translation.width
                }
            }
        }
        
        // MARK: Customize Handle Here
        // Add the gestures and visuals to the handle
        return handle
            .overlay(dragState.isDragging ? Circle().stroke(Color.gray, lineWidth: 2) : nil)
            .foregroundColor(.gray)
            .frame(width: handleSize.width, height: handleSize.height, alignment: .center)
            .offset(x: 0, y: currentOffset)
            .transaction { transaction in
                if disableAnimations {
                    transaction.disablesAnimations = true
                }
            }
            .gesture(longPressDrag)
    }
    
    // MARK: Money Shot
    public var body: some View {
        GeometryReader { (proxy: GeometryProxy) in
            VStack {
                self.top
                    .frame(height: self.paddingFactor*(self.pctSplit*proxy.frame(in: .local).height) + self.currentOffset)
                    .transaction { transaction in
                        if disableAnimations {
                            transaction.disablesAnimations = true
                        }
                    }
                Divider()
                self.bottom
                    .frame(height: self.paddingFactor*((1-self.pctSplit)*proxy.frame(in: .local).height) - self.currentOffset)
                    .transaction { transaction in
                        if disableAnimations {
                            transaction.disablesAnimations = true
                        }
                    }
            }
            .overlay(self.generateHandle(), alignment: .center)
        }
    }
}

// MARK: Init

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
extension VPart: View where Top: View, Bottom: View, Handle: View {
    
    /// # Vertical Partition With Custom Handle
    ///
    /// - parameters:
    ///    - top: Any type of View within a closure.
    ///    - bottom: Any type of View within a closure
    ///    - handle: Any type of View within a closure. The `Handle` is the view that the user will use to drag and resize the partitions.
    public init(disableAnimations: Bool = false, @ViewBuilder top: () -> Top, @ViewBuilder bottom: () -> Bottom, @ViewBuilder handle: () -> Handle) {
        self.disableAnimations = disableAnimations
        self.top = top()
        self.bottom = bottom()
        self.handle = handle()
    }
    
    /// # Vertical Partition With Custom Handle
    ///
    /// - parameters:
    ///    - pctSplit: The ratio of space the top takes up compared to the bottom. Use between 0 and 1.
    ///    - top: Any type of View within a closure.
    ///    - bottom: Any type of View within a closure
    ///    - handle: Any type of View within a closure. The `Handle` is the view that the user will use to drag and resize the partitions.
    public init(pctSplit: CGFloat, disableAnimations: Bool = false, @ViewBuilder top: () -> Top, @ViewBuilder bottom: () -> Bottom, @ViewBuilder handle: () -> Handle) {
        self.pctSplit = pctSplit
        self.disableAnimations = disableAnimations
        self.top = top()
        self.bottom = bottom()
        self.handle = handle()
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
extension VPart where Top: View, Bottom: View, Handle == Capsule {
    
    /// # Vertical Partition With Default Handle
    ///
    /// - parameters:
    ///    - top: Any type of View within a closure.
    ///    - bottom: Any type of View within a closure
    ///
    /// - note
    ///  The `Handle` used here is a `Capsule` that is wider than it is tall.
    public init(disableAnimations: Bool = false, @ViewBuilder top: () -> Top, @ViewBuilder bottom: () -> Bottom) {
        self.disableAnimations = disableAnimations
        self.top = top()
        self.bottom = bottom()
        self.handle = Capsule()
    }
    
    /// # Vertical Partition With Default Handle
    ///
    /// - parameters:
    ///    - pctSplit: The ratio of space the top takes up compared to the bottom. Use between 0 and 1.
    ///    - top: Any type of View within a closure.
    ///    - bottom: Any type of View within a closure
    ///
    /// - note
    ///  The `Handle` used here is a `Capsule` that is wider than it is tall.
    public init(pctSplit: CGFloat, disableAnimations: Bool = false, @ViewBuilder top: () -> Top, @ViewBuilder bottom: () -> Bottom) {
        self.pctSplit = pctSplit
        self.disableAnimations = disableAnimations
        self.top = top()
        self.bottom = bottom()
        self.handle = Capsule()
    }
}


import UIKit
import SwiftUI
import PlaygroundSupport

struct ContentView: View {
	var body: some View {
		MeasureBehaviour {
			TokenLineView([Token(icon: UIImage(systemName: "figure.walk"), info: "32", foreground: .white, background: .blue),
										 Token(title: "Bike", info: "24", foreground: .white, background: .green),
										 Token(title: "ICE", info: "50", foreground: .white, background: .red),
										 Token(icon: UIImage(systemName: "car.fill"), info: "477", foreground: .white, background: .blue),
										 Token(title: "Taxi", info: "321", foreground: .white, background: .blue),
										 Token(icon: UIImage(systemName: "airplane"), info: "666", foreground: .white, background: .orange)])
				.font(Font.body.bold())
		}
		.frame(width: 500, height: 600)
	}
}

struct TokenLineView: View {
	static let spacing: CGFloat = 2
	
	private let tokens: [Token]
	
	init(_ legs: [Token]) {
		tokens = legs + [Token(icon: UIImage(systemName: "ellipsis"), foreground: .white, background: .gray)]
	}
	
	@State private var boxes: [TokenBox] = []
	@State private var totalWidth: CGFloat = 0
	
	var body: some View {
		VStack(spacing: 0) {
			ZStack (alignment: .topLeading) {
				ForEach(tokens.indices, id: \.self) { index in
					TokenView(index: index, token: tokens[index])
						.tokenWidth(index)
						.alignmentGuide(Alignment.topLeading.horizontal) { _ in
							(index < self.boxes.count ? -self.boxes[index].offset : 0)
						}
						.padding([.trailing], (index < self.boxes.count ? -self.boxes[index].padding : 0))  // trick to clip the width
						.cornerRadius(TokenView.radius)
						.onPreferenceChange(TokenNameWidthPreference.self, perform: processNameWidths)
				}
				.onPreferenceChange(TokenWidthPreference.self, perform: processWidths)
			}
			Color
				.clear
				.frame(maxWidth: .infinity, maxHeight: 0)
				.tokenTotalWidth()
		}
		.onPreferenceChange(TokenTotalWidthPreference.self) { value in
			self.totalWidth = value
			render()
		}
	}
}

struct TokenView: View {
	static let padding: CGFloat = 5
	static let radius: CGFloat = 4

	let index: Int
	let token: Token
	
	public var body: some View {
		HStack (alignment: .center, spacing: 0) {
			if let title = token.title {
				Text(title)
					.lineLimit(1)
					.padding(TokenView.padding)
					.tokenNameWidth(index)
			}
			if let icon = token.icon { // https://swiftwithmajid.com/2020/05/13/template-view-pattern-in-swiftui/
				Text("00")
					.hidden()
					.overlay(Image(uiImage: icon)
										.renderingMode(.template)
										.resizable()
										.scaledToFit()
										.foregroundColor(token.foreground))
					.padding(TokenView.padding)
					.tokenNameWidth(index)
			}
			if let number = token.info {
				Text(number)
					.padding(EdgeInsets.init(top: TokenView.padding, leading: 0, bottom: TokenView.padding, trailing: TokenView.padding))
					.lineLimit(1)
			}
		}
		.foregroundColor(token.foreground)
		.background(token.background)
	}
}

struct TokenBox: Equatable {
	let width: CGFloat
	let nameWidth: CGFloat
	let offset: CGFloat
	let padding: CGFloat
	
	func with(width: CGFloat) -> TokenBox {
		TokenBox(width: width, nameWidth: nameWidth, offset: offset, padding: padding)
	}
	
	func with(nameWidth: CGFloat) -> TokenBox {
		TokenBox(width: width, nameWidth: nameWidth, offset: offset, padding: padding)
	}
	
	func with(offset: CGFloat, padding: CGFloat) -> TokenBox {
		TokenBox(width: width, nameWidth: nameWidth, offset: offset, padding: padding)
	}
}

extension TokenLineView {
	// create correct amount of initial boxes
	func prepareBoxes() -> [TokenBox] {
		var list = boxes
		if list.count < tokens.count {
			list.append(contentsOf: Array(repeating: TokenBox(width: 0, nameWidth: 0, offset: 0, padding: 0), count: tokens.count - boxes.count))
		}
		return list
	}
	
	// store name width into boxes
	func processNameWidths(widths: [Int: CGFloat]) {
		var list = prepareBoxes()
		for idx in 0..<tokens.count {
			guard let w = widths[idx] else { continue }
			
			if idx < boxes.count {
				let box = boxes[idx]
				list[idx] = box.with(nameWidth: w)
			}
			else {
				list[idx] = TokenBox(width: 0, nameWidth: w, offset: 0, padding: 0)
			}
		}
		boxes = list
		render()
	}
	
	// store chips widths into boxes
	func processWidths(widths: [Int: CGFloat]) {
		var list = prepareBoxes()
		for idx in 0..<tokens.count {
			guard let w = widths[idx] else { continue }
			
			if idx < boxes.count {
				let box = boxes[idx]
				list[idx] = box.with(width: w)
			}
			else {
				list[idx] = TokenBox(width: w, nameWidth: 0, offset: 0, padding: 0)
			}
		}
		boxes = list
		
		render()
	}
	
	// optimize dimensions according total width
	func render() {
		guard boxes.count == tokens.count else { return }
		
		var list = [TokenBox]()
		var cutoffCount = 0
		var computedWidth: CGFloat = 0
		repeat {
			list = computeBoxes(cutoffCount: cutoffCount)
			computedWidth = list.last!.offset + list.last!.width - list.last!.padding
			cutoffCount += 1
		} while computedWidth > totalWidth && cutoffCount < boxes.count
		
		if computedWidth > totalWidth {
			cutoffCount = 0
			repeat {
				list = computeBoxes(cutoffCount: cutoffCount, dropEllipsis: false)
				computedWidth = list.last!.offset + list.last!.width - list.last!.padding
				cutoffCount += 1
			} while computedWidth > totalWidth && cutoffCount < boxes.count
		}
		if list != boxes {
			boxes = list
		}
	}
	
	// calculate offsets and paddings according to number of dropped items
	func computeBoxes(cutoffCount: Int, dropEllipsis: Bool = true) -> [TokenBox] {
		var list: [TokenBox] = []
		for (index, box) in boxes.enumerated() {
			var pos: CGFloat = 0
			var width = box.width
			if dropEllipsis {
				if index == boxes.count - 1 {   // hide ellipsis
					width = 0
				}
				else if index >= boxes.count - cutoffCount { // shorten to name from tail
					width = box.nameWidth
				}
			}
			else {
				if index == boxes.count - 1 {   // show ellipsis
					width = box.width
				}
				else if index >= boxes.count - cutoffCount { // short to 0 from tail
					width = -TokenLineView.spacing   // compensates pos spacing
				}
				else if index > 0 { // shorten to name
					width = box.nameWidth
				}
			}
			if index > 0 {
				pos += list.last!.offset + list.last!.width - list.last!.padding + TokenLineView.spacing
			}
			list.append(box.with(offset: pos, padding: box.width - width))
		}
		return list
	}
}

struct TokenTotalWidthPreference: PreferenceKey {
	static let defaultValue: CGFloat = 0
	static func reduce(value: inout Value, nextValue: () -> Value) {
		value = nextValue()
	}
}

struct TokenWidthPreference: PreferenceKey {
	static let defaultValue: [Int: CGFloat] = [:]
	static func reduce(value: inout Value, nextValue: () -> Value) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}

struct TokenNameWidthPreference: PreferenceKey {
	static let defaultValue: [Int: CGFloat] = [:]
	static func reduce(value: inout Value, nextValue: () -> Value) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}

extension View {
	func tokenTotalWidth() -> some View {
		background(GeometryReader { proxy in
			Color.clear.preference(key: TokenTotalWidthPreference.self, value: proxy.size.width)
		})
	}
	
	func tokenWidth(_ index: Int) -> some View {
		background(GeometryReader { proxy in
			Color.clear.preference(key: TokenWidthPreference.self, value: [index: proxy.size.width])
		})
	}
	
	func tokenNameWidth(_ index: Int) -> some View {
		background(GeometryReader { proxy in
			Color.clear.preference(key: TokenNameWidthPreference.self, value: [index: proxy.size.width])
		})
	}
}

struct Token {
	let title: String?
	let icon: UIImage?
	let info: String?
	let foreground: Color
	let background: Color
	
	init(title: String? = nil, icon: UIImage? = nil, info: String? = nil, foreground: Color = .accentColor, background: Color = .clear) {
		self.title = title
		self.icon = icon
		self.info = info
		self.foreground = foreground
		self.background = background
	}
}

struct MeasureBehaviour<Content: View>: View {
	@State private var width: CGFloat = 400
	var content: Content
	
	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}
	
	var body: some View {
		VStack {
			Spacer()
			content
				.frame(width: width, height: 400)
				.background(Color.white)
			Spacer()
			Slider(value: $width, in: 0...500)
		}
		.background(Color.gray)
	}
}

PlaygroundPage.current.setLiveView(ContentView())

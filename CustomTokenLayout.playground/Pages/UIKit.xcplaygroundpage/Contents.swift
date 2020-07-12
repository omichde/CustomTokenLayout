import UIKit
import PlaygroundSupport

class TokenLineView: UIView {
	static let spacing: CGFloat = 2

	private let tokens: [Token]

	required init?(coder: NSCoder) {
		tokens = [Token]()
		super.init(coder: coder)
	}

	init (_ tokens: [Token]) {
		let list = tokens + [Token(icon: UIImage(systemName: "ellipsis"), foreground: .white, background: .gray)]
		self.tokens = list
		
		var views = [TokenView]()
		var height: CGFloat = 0
		list.forEach {
			let tv = TokenView($0)
			height = max(height, tv.bounds.height)
			views.append(tv)
		}
		super.init(frame: CGRect(x: 0, y: 0, width: 0, height: height))
		views.forEach {
			$0.frame.size.height = height
			addSubview($0)
		}
	}

	override func layoutSubviews() {
		let totalWidth = bounds.width

		var cutoffCount = 0
		var computedWidth: CGFloat = 0
		repeat {
			computedWidth = computeBoxes(cutoffCount: cutoffCount)
			cutoffCount += 1
		} while computedWidth > totalWidth && cutoffCount < tokens.count
		
		if computedWidth > totalWidth {
			cutoffCount = 0
			repeat {
				computedWidth = computeBoxes(cutoffCount: cutoffCount, dropEllipsis: false)
				cutoffCount += 1
			} while computedWidth > totalWidth && cutoffCount < tokens.count
		}
	}

	func computeBoxes(cutoffCount: Int, dropEllipsis: Bool = true) -> CGFloat {

		let boxes = subviews as! [TokenView]
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
					pos -= CGFloat(cutoffCount - 1) * TokenLineView.spacing
				}
				else if index >= boxes.count - cutoffCount { // short to 0 from tail
					width = 0   // compensates pos spacing
				}
				else if index > 0 { // shorten to name
					width = box.nameWidth
				}
			}
			if index > 0 {
				pos += boxes[index-1].frame.maxX + TokenLineView.spacing
			}
			box.frame = CGRect(x: pos, y: 0, width: width, height: box.frame.height)
		}
		return boxes.last!.frame.maxX
	}
}

class TokenView: UIView {
	static let padding: CGFloat = 5
	static let radius: CGFloat = 4

	private(set) var width: CGFloat = 0
	private(set) var nameWidth: CGFloat = 0
	private let token: Token

	required init?(coder: NSCoder) {
		token = Token()
		super.init(coder: coder)
	}

	init (_ token: Token) {
		self.token = token

		var views = [UIView]()
		var height: CGFloat = 0
		if let title = token.title {
			let label = UILabel(frame: .zero)
			label.text = title
			label.textColor = token.foreground
			label.backgroundColor = token.background
			label.numberOfLines = 1
			label.lineBreakMode = .byClipping
			label.textAlignment = .center
			label.contentMode = .center
			label.sizeToFit()
			label.clipsToBounds = true
			label.autoresizingMask = .flexibleHeight
			label.frame.size.width = label.bounds.width + 2 * TokenView.padding
			views.append(label)
			nameWidth = label.bounds.width
			width = nameWidth
			height = max(height, label.bounds.height)
		}
		
		if let icon = token.icon {
			let img = UIImageView(image: icon.withTintColor(token.foreground, renderingMode: .alwaysOriginal))
			img.backgroundColor = token.background
			img.contentMode = .center
			img.clipsToBounds = true
			img.autoresizingMask = .flexibleHeight
			img.frame.size.width = img.bounds.width + 2 * TokenView.padding
			views.append(img)
			nameWidth = img.bounds.width
			width = nameWidth
			height = max(height, img.bounds.height)
		}

		if let info = token.info {
			let label = UILabel(frame: .zero)
			label.text = info
			label.textColor = token.foreground
			label.backgroundColor = token.background
			label.numberOfLines = 1
			label.lineBreakMode = .byClipping
			label.contentMode = .center
			label.sizeToFit()
			label.clipsToBounds = true
			label.autoresizingMask = .flexibleHeight
			label.frame = CGRect(x: nameWidth, y: 0, width: label.bounds.width + TokenView.padding, height: label.bounds.height)
			views.append(label)
			width = nameWidth + label.bounds.width
		}

		height += 2 * TokenView.padding
		super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
		views.forEach {
			$0.frame.size.height = height
			addSubview($0)
		}

		layer.cornerRadius = TokenView.radius
		clipsToBounds = true
	}
}

struct Token {
	let title: String?
	let icon: UIImage?
	let info: String?
	let foreground: UIColor
	let background: UIColor
	
	init(title: String? = nil, icon: UIImage? = nil, info: String? = nil, foreground: UIColor = UIView().tintColor, background: UIColor = .clear) {
		self.title = title
		self.icon = icon
		self.info = info
		self.foreground = foreground
		self.background = background
	}
}

class MeasureView: UIView {
	
	private var container: UIView!
	
	required init?(coder: NSCoder) { super.init(coder: coder) }
	
	init(content: UIView) {
		super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 600))
		
		backgroundColor = .gray
		
		container = UIView(frame: rectForContainer(width: 400))
		container.backgroundColor = .white
		addSubview(container)
		
		content.frame.size.width = container.frame.size.width
		content.frame.origin.y = (container.frame.size.height - content.frame.size.height) / 2
		content.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
		container.addSubview(content)
		
		let slider = UISlider(frame: CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30))
		slider.maximumValue = Float(frame.width)
		slider.value = Float(container.frame.width)
		slider.autoresizingMask = .flexibleWidth
		slider.addTarget(self, action: #selector(changeSlider(sender:)), for: .valueChanged)
		addSubview(slider)
	}
	
	func rectForContainer(width: CGFloat) -> CGRect {
		CGRect(x: (500 - width) / 2, y: 100, width: width, height: 400)
	}
	
	@objc func changeSlider(sender: UISlider) {
		container.frame = rectForContainer(width: CGFloat(sender.value))
	}
}

PlaygroundPage
	.current
	.liveView = MeasureView(content:
									TokenLineView([Token(icon: UIImage(systemName: "figure.walk"), info: "32", foreground: .white, background: .blue),
																 Token(title: "Bike", info: "24", foreground: .white, background: .green),
																 Token(title: "ICE", info: "50", foreground: .white, background: .red),
																 Token(icon: UIImage(systemName: "car.fill"), info: "477", foreground: .white, background: .blue),
																 Token(title: "Taxi", info: "321", foreground: .white, background: .blue),
																 Token(icon: UIImage(systemName: "airplane"), info: "666", foreground: .white, background: .orange)])
	)

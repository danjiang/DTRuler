//
//  DTRuler.swift
//  DTRuler
//
//  Created by Dan Jiang on 2016/12/22.
//
//

import UIKit

// MARK: - DTRulerTheme

public protocol DTRulerTheme {
  var backgroundColor: UIColor { get }
  var pointerColor: UIColor { get }
  var majorScaleColor: UIColor { get }
  var minorScaleColor: UIColor { get }
  var labelColor: UIColor { get }
}

public extension DTRulerTheme {
  
  var backgroundColor: UIColor {
    return UIColor.lightGray
  }
  
  var pointerColor: UIColor {
      return UIColor.gray
  }
  
  var majorScaleColor: UIColor {
    return UIColor.darkGray
  }
  
  var minorScaleColor: UIColor {
    return UIColor.darkGray
  }
  
  var labelColor: UIColor {
    return UIColor.darkGray
  }

}

// MARK: - DTRulerDelegate

public protocol DTRulerDelegate {
  func didChange(on ruler: DTRuler, withScale scale: DTRuler.Scale)
}


// MARK: - DTRuler

public class DTRuler: UIView {
  
  public enum Scale: Comparable {
    
    case integer(Int)
    case float(Float)
    
    public static func ==(lhs: Scale, rhs: Scale) -> Bool {
      switch lhs {
      case .integer(let i1):
        switch rhs {
        case .integer(let i2):
          return i1 == i2
        default:
          return false
        }
      case .float(let f1):
        switch rhs {
        case .float(let f2):
          return f1 == f2
        default:
          return false
        }
      }
    }
    
    public static func <(lhs: Scale, rhs: Scale) -> Bool {
      switch lhs {
      case .integer(let i1):
        switch rhs {
        case .integer(let i2):
          return i1 < i2
        default:
          return false
        }
      case .float(let f1):
        switch rhs {
        case .float(let f2):
          return f1 < f2
        default:
          return false
        }
      }
    }
    
    public func next() -> Scale {
      switch self {
      case .integer(let i):
        return Scale.integer(i + 10)
      case .float(let f):
        return Scale.float(f + 1)
      }
    }
    
    public func previous() -> Scale {
      switch self {
      case .integer(let i):
        return Scale.integer(i - 10)
      case .float(let f):
        return Scale.float(f - 1)
      }
    }
    
    public func majorTextRepresentation() -> String {
      switch self {
      case .integer(let i):
        return "\(i)"
      case .float(let f):
        let floatDivision = f/12
        let isFoot = floor(floatDivision) == floatDivision // true
        if (isFoot) {
            return String(format: "%0.f\r%0.fF", f, floatDivision)
        }
        else {
            if f > 12 {
                var remainder = f
                while (remainder > 12) {
                    remainder = remainder - 12
                }
                return String(format: "%0.f\r%0.f", f, remainder)
            }
            return String(format: "%.0f", f)
        }
      }
    }
    
    public func minorTextRepresentation() -> String {
      switch self {
      case .integer(let i):
        return "\(i)"
      case .float(let f):
        return String(format: "%.f", f)
      }
    }
    
  }
  
  public struct DefaultTheme: DTRulerTheme {}

  public static var theme: DTRulerTheme = DefaultTheme()
  
  public var delegate: DTRulerDelegate?
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public init(scale: Scale, minScale: Scale, maxScale: Scale, width: CGFloat) {
    super.init(frame: .zero)
    
    // TODO: Validate Scales
    
    layoutRuler(with: scale, minScale, maxScale, width)
    layoutPointer()
  }
  
  // MARK: - Private

  private func layoutPointer() {
    let pointer = RulerPointer()
    
    addSubview(pointer)
    
    pointer.translatesAutoresizingMaskIntoConstraints = false
    
    let width = NSLayoutConstraint(item: pointer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 18)
    let height = NSLayoutConstraint(item: pointer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 14)
    
    pointer.addConstraints([width, height])
    
    let top = NSLayoutConstraint(item: pointer, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
    let centerX = NSLayoutConstraint(item: pointer, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
    
    addConstraints([top, centerX])
  }
  
  private func layoutRuler(with scale: Scale, _ minScale: Scale, _ maxScale: Scale, _ width: CGFloat) {
    let ruler = Ruler(minorScale: scale, minMajorScale: minScale, maxMajorScale: maxScale, width: width)
    ruler.rulerDelegate = self
    
    addSubview(ruler)
    
    ruler.translatesAutoresizingMaskIntoConstraints = false
    
    let height = NSLayoutConstraint(item: ruler, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: RulerBlock.height)

    ruler.addConstraints([height])
    
    let top = NSLayoutConstraint(item: ruler, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
    let bottom = NSLayoutConstraint(item: ruler, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
    let leading = NSLayoutConstraint(item: ruler, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
    let trailing = NSLayoutConstraint(item: ruler, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
    
    addConstraints([top, bottom, leading, trailing])
  }

}

extension DTRuler: RulerDelegate {
  
  func didChange(on ruler: Ruler, withMinorScale minorScale: DTRuler.Scale) {
    delegate?.didChange(on: self, withScale: minorScale)
  }
  
}

// MARK: - Ruler

protocol RulerDelegate {
  func didChange(on ruler: Ruler, withMinorScale minorScale: DTRuler.Scale)
}

class Ruler: UIScrollView, UIScrollViewDelegate {
  
  var rulerDelegate: RulerDelegate?
  
  private let minMajorScale: DTRuler.Scale
  private let maxMajorScale: DTRuler.Scale
  
  private let numberOfBlocks = 7
  private var lastTime: TimeInterval = 0
  private let container = UIView()
  private var majorScales: [DTRuler.Scale] = []
  private var rulerBlocks = [RulerBlock]()
  private var reusedRulerBlocks = [RulerBlock]()
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(minorScale: DTRuler.Scale, minMajorScale: DTRuler.Scale, maxMajorScale: DTRuler.Scale, width: CGFloat) {
    self.minMajorScale = minMajorScale
    self.maxMajorScale = maxMajorScale
    
    super.init(frame: .zero)
    
    contentSize = CGSize(width: RulerBlock.width * CGFloat(numberOfBlocks), height: RulerBlock.height)
    showsHorizontalScrollIndicator = false
    delegate = self
    
    container.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: RulerBlock.height)
    container.isUserInteractionEnabled = false
    addSubview(container)
    
    var majorScale: DTRuler.Scale
    var minorScaleInteger: Int
    switch minorScale {
    case .integer(let i):
      minorScaleInteger = i % 10
      majorScale = .integer(i - minorScaleInteger)
    case .float(let f):
      let tmp = Int((f * 10).rounded())
      minorScaleInteger = tmp % 10
      majorScale = .float(Float(tmp / 10))
    }
    var offsetGapNumber = 0
    if minorScaleInteger <= 4 {
      offsetGapNumber = minorScaleInteger + 5
    } else {
      offsetGapNumber = minorScaleInteger - 5
      majorScale = majorScale.next()
    }
    
    var startX = width / 2 - RulerBlock.gap / 2 // point to middle ruler block`s first scale
    startX -= CGFloat(offsetGapNumber) * RulerBlock.gap // first scale with right gap offset
    
    let indexs = [0, -1, -2, -3, 1, 2, 3]
    for i in 0..<numberOfBlocks {
      let index = indexs[i]
      placeMajorScale(index == 0 ? majorScale : nil, previous: index < 0) { (frame: CGRect) -> CGRect in
        var newFrame = frame
        newFrame.origin.x += startX + newFrame.size.width * CGFloat(index)
        return newFrame
      }
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    recenterIfNecessary()
    
    let minVisibleX = visibleBounds().minX
    let maxVisibleX = visibleBounds().maxX
    
    tileChildrens(from: minVisibleX, to: maxVisibleX)
  }
  
  func recenterIfNecessary() {
    let currentOffset = contentOffset
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2.0
    let distanceFromCenterSign = currentOffset.x - centerOffsetX
    let distanceFromCenter = fabs(distanceFromCenterSign)
    if distanceFromCenter > centerOffsetX {
      contentOffset = CGPoint(x: centerOffsetX, y: currentOffset.y)
      // move content by the same amount so it appears to stay still
      moveAllChildrens(with: -distanceFromCenterSign, animation: false)
    }
  }
  
  func moveAllChildrens(with offsetX: CGFloat, animation: Bool) {
    if animation {
      UIView.animate(withDuration: 0.2, animations: { 
        for rulerBlock in self.rulerBlocks {
          rulerBlock.center = CGPoint(x: rulerBlock.center.x + offsetX, y: rulerBlock.center.y)
        }
      })
    } else {
      for rulerBlock in rulerBlocks {
        rulerBlock.center = CGPoint(x: rulerBlock.center.x + offsetX, y: rulerBlock.center.y)
      }
    }
  }
  
  func visibleBounds() -> CGRect {
    return convert(bounds, to: container)
  }
  
  func placeMajorScale(_ majorScale: DTRuler.Scale?, previous: Bool, calculateFrame: (_ frame: CGRect) -> CGRect) {
    var rulerBlock: RulerBlock
    if let reusedRulerBlock = reusedRulerBlocks.last {
      rulerBlock = reusedRulerBlock
    } else {
      rulerBlock = RulerBlock(label: "")
    }
    
    var newMajorScale: DTRuler.Scale
    if !previous {
      if let majorScale = majorScale {
        newMajorScale = majorScale
      } else {
        newMajorScale = nextMajorScale()
      }
      majorScales.append(newMajorScale)
      rulerBlocks.append(rulerBlock)
      container.addSubview(rulerBlock)
    } else {
      newMajorScale = previousScale()
      majorScales.insert(newMajorScale, at: 0)
      rulerBlocks.insert(rulerBlock, at: 0)
      container.insertSubview(rulerBlock, at: 0)
    }
    rulerBlock.label = newMajorScale.majorTextRepresentation()
    rulerBlock.frame = calculateFrame(rulerBlock.frame)
  }
  
  func previousScale() -> DTRuler.Scale {
    let majorScale = majorScales.first!
    if majorScale > minMajorScale {
      return majorScale.previous()
    } else {
      return maxMajorScale
    }
  }
  
  func nextMajorScale() -> DTRuler.Scale {
    let majorScale = majorScales.last!
    if majorScale < maxMajorScale {
      return majorScale.next()
    } else {
      return minMajorScale
    }
  }
  
  func tileChildrens(from minVisibleX: CGFloat, to maxVisibleX: CGFloat) {
    // add child that are missing on right side
    if let last = rulerBlocks.last {
      let rightEdge = last.frame.maxX
      if rightEdge < maxVisibleX {
        placeMajorScale(nil, previous: false) { (frame: CGRect) -> CGRect in
          var newFrame = frame
          newFrame.origin.x = rightEdge
          return newFrame
        }
      }
    }
    
    // add child that are missing on left side
    if let first = rulerBlocks.first {
      let leftEdge = first.frame.minX
      if leftEdge > minVisibleX {
        placeMajorScale(nil, previous: true) { (frame: CGRect) -> CGRect in
          var newFrame = frame
          newFrame.origin.x = leftEdge - newFrame.size.width
          return newFrame
        }
      }
    }
    
    if rulerBlocks.count > numberOfBlocks {
      // remove child that have fallen off right edge
      if let last = rulerBlocks.last {
        let leftEdge = last.frame.minX
        if leftEdge > maxVisibleX {
          reusedRulerBlocks.append(last)
          majorScales.removeLast()
          rulerBlocks.removeLast()
          last.removeFromSuperview()
        }
      }
      // remove child that have fallen off left edge
      if let first = rulerBlocks.first {
        let rightEdge = first.frame.maxX
        if rightEdge < minVisibleX {
          reusedRulerBlocks.append(first)
          majorScales.removeFirst()
          rulerBlocks.removeFirst()
          first.removeFromSuperview()
        }
      }
    }
  }
  
  func pointToMinorScale(with revise: Bool) -> DTRuler.Scale? {
    var minorScale: DTRuler.Scale? = nil
    let midVisibleX = visibleBounds().midX
    for i in 0..<rulerBlocks.count {
      let rulerBlock = rulerBlocks[i]
      let rulerBlockMinX = rulerBlock.frame.minX
      let rulerBlockMaxX = rulerBlock.frame.maxX
      // point to which ruler block
      if rulerBlockMinX <= midVisibleX && midVisibleX < rulerBlockMaxX {
        let majorScale = majorScales[i]
        for j in 0..<10 {
          let minorScaleMinX = rulerBlockMinX + CGFloat(j) * RulerBlock.gap
          let minorScaleMidX = minorScaleMinX + RulerBlock.gap / 2
          let minorScaleMaxX = rulerBlockMinX + CGFloat(j + 1) * RulerBlock.gap
          // point to which ruler block`s minor scale
          if minorScaleMinX <= midVisibleX && midVisibleX < minorScaleMaxX {
            switch majorScale {
            case .integer(let i):
              minorScale = .integer(i + (j - 5))
            case .float(let f):
              minorScale = .float(f + Float(j - 4) * 0.125)
            }
            // point to minor scale without offset
            if (revise) {
              moveAllChildrens(with: midVisibleX - minorScaleMidX, animation: true)
            }
            break
          }
        }
        break
      }
    }
    return minorScale
  }
  
  func isEnoughTimeElapsed() -> Bool {
    let currentTime = Date().timeIntervalSince1970
    var isEnough = false
    if lastTime == 0 {
      isEnough = true
    } else {
      isEnough = currentTime - lastTime > 0.016 // 16.67 milliseconds per frame
    }
    lastTime = currentTime
    return isEnough
  }
  
  // MARK: - UIScrollViewDelegate

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if let minorScale = pointToMinorScale(with: true) {
      rulerDelegate?.didChange(on: self, withMinorScale: minorScale)
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if let minorScale = pointToMinorScale(with: true) {
      rulerDelegate?.didChange(on: self, withMinorScale: minorScale)
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if isEnoughTimeElapsed() {
      if let minorScale = pointToMinorScale(with: false) {
        rulerDelegate?.didChange(on: self, withMinorScale: minorScale)
      }
    }
  }
  
}

// MARK: - RulerPointer

class RulerPointer: UIView {
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    
    DTRuler.theme.pointerColor.setFill()
    
    context.move(to: .zero)
    context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    context.addLine(to: CGPoint(x: rect.maxX, y: 0))
    context.closePath()
    context.fillPath()
  }
  
}

// MARK: - RulerBlock

class RulerBlock: UIView {
  
  static let width: CGFloat = 100
  static let height: CGFloat = 89
  static let gap: CGFloat = 12.5

  var label: String {
    didSet {
      setNeedsDisplay()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(label: String) {
    self.label = label
    super.init(frame: CGRect(x: 0, y: 0, width: RulerBlock.width, height: RulerBlock.height))
    backgroundColor = DTRuler.theme.backgroundColor
  }
  
  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    
    let startX = rect.midX + RulerBlock.gap / 2
    let startY = rect.minY
    
    // Draw label
    
    let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .regular), NSAttributedStringKey.foregroundColor: DTRuler.theme.labelColor]
    let attributedLabel = NSAttributedString(string: label, attributes: attributes)
    let size = attributedLabel.size()
    attributedLabel.draw(in: CGRect(x: startX - size.width / 2, y: startY + frame.size.height * 0.46875 + 4, width: size.width, height: size.height))
    
    // Draw major scale
    
    DTRuler.theme.majorScaleColor.setStroke()

    context.setLineWidth(2)
    context.move(to: CGPoint(x: startX, y: startY))
    context.addLine(to: CGPoint(x: startX, y: frame.size.height * 0.46875))
    context.drawPath(using: .stroke)
    
    // Draw minor scales

    DTRuler.theme.minorScaleColor.setStroke()

    drawMinorScalesFromMidToEgde(with: startX, startY: startY, counter: 4, plus: true, context: context)
    drawMinorScalesFromMidToEgde(with: startX, startY: startY, counter: 4, plus: false, context: context)
  }
  
    private func drawMinorScalesFromMidToEgde(with startX: CGFloat, startY: CGFloat, counter: Int, plus: Bool, context: CGContext) {
        
        context.setLineWidth(1)
        var x = startX
        for i in 0..<counter {
            if plus {
                x += RulerBlock.gap
            } else {
                x -= RulerBlock.gap
            }
            context.move(to: CGPoint(x: x, y: startY))
            if i == 3 {
                context.addLine(to: CGPoint(x: x, y: frame.size.height * 0.4125))
            }
            else if i == 1 {
                context.addLine(to: CGPoint(x: x, y: frame.size.height * 0.3525))
            }
            else{
                context.addLine(to: CGPoint(x: x, y: frame.size.height * 0.3125))
            }
            context.drawPath(using: .stroke)
        
        
        
    }
  }
  
}

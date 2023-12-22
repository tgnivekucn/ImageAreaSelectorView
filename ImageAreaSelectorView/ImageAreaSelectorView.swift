//
//  ImageAreaSelectorView.swift
//  ImageAreaSelectorView
//
//  Created on 2023/12/22.
//

import UIKit

// "ImageCropEdiorView supports below features:
// 1. Pinch to change the size of the select area.
// 2. Move to change the position of the select area.
// 3. Move vertices of the select area to change its size.
//
// Note: The above three operations must consider that the four vertices cannot exceed the boundaries of the View, and the select area has a minimum size of 50*50."
class ImageAreaSelectorView: UIView {
//    private var imageView: UIImageView?
    private let maskBorderLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = CGFloat(5)
        return shapeLayer
    }()
    private var selectAreaSize: CGSize = .zero
    private var selectAreaFrame: CGRect = .zero {
        didSet {
            customMaskView.frame = self.selectAreaFrame
            setTargetImage(frame: self.selectAreaFrame)
        }
    }
    private let minimumSelectAreaSize = CGSize(width: 50, height: 50)
    private var minScale: CGFloat {
        let scaleX = CGFloat(50) / selectAreaFrame.width
        let scaleY = CGFloat(50) / selectAreaFrame.height
        return max(scaleX, scaleY)
    }

    private var maxScale: CGFloat {
        return self.getMaxScale(selectAreaFrame: selectAreaFrame, targetFrame: self.frame)
    }

    private var scale: CGFloat = 1
    private var inMoveMode: Bool = false
    private var startPoint: CGPoint?
    private var customMaskView: UIView = UIView()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEvent()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEvent()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("test11 layoutSubviews, timestamp: \(Date().timeIntervalSince1970)")
    }
    
    private func setupEvent() {
        customMaskView.frame = CGRect(origin: .zero, size: self.frame.size)
        customMaskView.backgroundColor = .black.withAlphaComponent(0.4)
        self.addSubview(customMaskView)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        self.addGestureRecognizer(pinchGesture)
    }
    
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            break
        case .changed, .ended:
            if gesture.scale <= minScale {
                scale = minScale
            } else if gesture.scale >= maxScale {
                scale = maxScale
            } else {
                scale = gesture.scale
            }
            if gesture.state == .changed || gesture.state == .ended {
                let frame = getFrameAfterScale(scale: scale,
                                               centerPoint: getCenterPointOfFrame(frame: selectAreaFrame),
                                               selectAreaFrameSize: selectAreaFrame.size)
                if isValidFrame(frame: frame) {
                    selectAreaFrame = frame
                }
            }
        case .cancelled, .failed:
            scale = 1.0
        default:
            break
        }
    }

    // MARK: - Touch related methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = getPointInView(touch: touch, event: event)
        startPoint = currentPoint
        inMoveMode = isInMoveMode(touchPoint: currentPoint, selectAreaFrame: selectAreaFrame)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = getPointInView(touch: touch, event: event)
        if inMoveMode {
            let point = getSelectAreaOriginPoint(touchPoint: currentPoint,
                                                 selectAreaSize: selectAreaFrame.size,
                                                 targetSize: self.frame.size)
            let frame = CGRect(origin: point, size: selectAreaFrame.size)
            if isValidFrame(frame: frame) {
                selectAreaFrame = frame
            }
        } else {
            let vertexWithFixedPosition = getNearestVertex(touchPoint: currentPoint,
                                                           selectAreaFrame: selectAreaFrame)
            let frame = createRect(from: vertexWithFixedPosition, to: currentPoint)
            if isValidFrame(frame: frame) {
                selectAreaFrame = frame
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = getPointInView(touch: touch, event: event)
        inMoveMode = isInMoveMode(touchPoint: currentPoint, selectAreaFrame: selectAreaFrame)
    }

    func setTargetImage(frame: CGRect) {
        print("test11 current target image frame is: \(frame)")
    }

    // MARK: - Private methods
    func getPointInView(touch: UITouch, event: UIEvent?) -> CGPoint {
        let currentPoint: CGPoint
        if let predicted = event?.predictedTouches(for: touch), let lastPoint = predicted.last {
            currentPoint = lastPoint.location(in: self)
        } else {
            currentPoint = touch.location(in: self)
        }
        return currentPoint
    }

    func isInMoveMode(touchPoint: CGPoint, selectAreaFrame: CGRect) -> Bool {
        let centerAreaWidth = selectAreaFrame.width / CGFloat(3)
        let centerAreaHeight = selectAreaFrame.height / CGFloat(3)
        let centerAreaFrame = selectAreaFrame.insetBy(dx: centerAreaWidth, dy: centerAreaHeight)
        return centerAreaFrame.contains(touchPoint)
    }

    func getCenterPointOfFrame(frame: CGRect) -> CGPoint {
        let x = frame.minX + (frame.width / 2)
        let y = frame.minY + (frame.height / 2)
        return CGPoint(x: x, y: y)
    }

    func getFrameAfterScale(scale: Double, centerPoint: CGPoint, selectAreaFrameSize: CGSize) -> CGRect {
        let resultWidth = selectAreaFrameSize.width * scale
        let resultHeight = selectAreaFrameSize.height * scale
        let resultOriginX = centerPoint.x - (resultWidth / 2)
        let resultOriginY = centerPoint.y - (resultHeight / 2)
        return CGRect(x: resultOriginX, y: resultOriginY, width: resultWidth, height: resultHeight)
    }

    func getSelectAreaOriginPoint(touchPoint: CGPoint, selectAreaSize: CGSize, targetSize: CGSize,
                                  lineWidth: CGFloat = 0) -> CGPoint {
        let halfLineWidth = lineWidth / 2
        let adjustedWidth = selectAreaSize.width + lineWidth
        let adjustedHeight = selectAreaSize.height + lineWidth

        var tmpX = touchPoint.x - (selectAreaSize.width / 2)
        tmpX = max(halfLineWidth, tmpX)
        tmpX = min(tmpX, targetSize.width - adjustedWidth)

        var tmpY = touchPoint.y - (selectAreaSize.height / 2)
        tmpY = max(0, tmpY)
        tmpY = min(tmpY, targetSize.height - adjustedHeight)

        return CGPoint(x: tmpX, y: tmpY)
    }

    func getNearestVertex(touchPoint: CGPoint, selectAreaFrame: CGRect) -> CGPoint {
        let topLeftPoint = selectAreaFrame.origin
        let topRightPoint = CGPoint(x: selectAreaFrame.maxX, y: selectAreaFrame.minY)
        let bottomLeftPoint = CGPoint(x: selectAreaFrame.minX, y: selectAreaFrame.maxY)
        let bottomRightPoint = CGPoint(x: selectAreaFrame.maxX, y: selectAreaFrame.maxY)
        
        let points = [topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint]
        let diagonallyOppositePointArr = [bottomRightPoint, bottomLeftPoint, topRightPoint, topLeftPoint]
        
        let minDiffPoint = points.min(by: {
            abs($0.x - touchPoint.x) + abs($0.y - touchPoint.y) <
                abs($1.x - touchPoint.x) + abs($1.y - touchPoint.y)
        }) ?? selectAreaFrame.origin
        
        if let index = points.firstIndex(of: minDiffPoint) {
            return diagonallyOppositePointArr[index]
        }
        return selectAreaFrame.origin
    }

    private func createRect(from: CGPoint, to: CGPoint) -> CGRect {
        return CGRect(x: min(from.x, to.x),
                      y: min(from.y, to.y),
                      width: abs(to.x - from.x),
                      height: abs(to.y - from.y))
    }

    // Check if all points of the frame are within EditorView
    func isValidFrame(frame: CGRect) -> Bool {
        if !checkIfVertexOutOfBound(frame: frame, targetSize: self.frame.size) &&
            !checkIfLargerThanViewSize(frame: frame, targetFrame: self.frame) &&
            !checkIfSmallerThanMinSize(frame: frame) {
            return true
        }
        return false
    }

    func checkIfVertexOutOfBound(frame: CGRect, targetSize: CGSize) -> Bool {
        let viewWidth = targetSize.width
        let viewHeight = targetSize.height

        if (frame.minX >= 0) && (frame.maxX <= viewWidth)
            && (frame.minY >= 0) && (frame.maxY <= viewHeight) {
            return false
        }
        return true
    }

    func checkIfLargerThanViewSize(frame: CGRect, targetFrame: CGRect) -> Bool {
        let lhs = frame
        let rhs = targetFrame
        return (lhs.width > rhs.width) && (lhs.height > rhs.height)
    }

    func checkIfSmallerThanMinSize(frame: CGRect) -> Bool {
        let lhs = frame.size
        let rhs = minimumSelectAreaSize
        return (lhs.width < rhs.width) && (lhs.height < rhs.height)
    }
    
    func getMaxScale(selectAreaFrame: CGRect, targetFrame: CGRect) -> CGFloat {
        let scaleX = targetFrame.width / selectAreaFrame.width
        let scaleY = targetFrame.height / selectAreaFrame.height
        return min(scaleX, scaleY)
    }
}

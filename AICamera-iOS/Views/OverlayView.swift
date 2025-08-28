import SwiftUI

struct OverlayView: View {
    let circles: [Circle]
    let imageSize: CGSize
    let containerSize: CGSize
    let scale: CGFloat
    let offset: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Calculate scaling factors
            let scaleX = containerSize.width / imageSize.width
            let scaleY = containerSize.height / imageSize.height
            let uniformScale = min(scaleX, scaleY)
            
            // Calculate centered position
            let scaledWidth = imageSize.width * uniformScale
            let scaledHeight = imageSize.height * uniformScale
            let centerOffsetX = (containerSize.width - scaledWidth) / 2
            let centerOffsetY = (containerSize.height - scaledHeight) / 2
            
            // Apply transformations
            context.translateBy(x: centerOffsetX + offset.width, y: centerOffsetY + offset.height)
            context.scaleBy(x: uniformScale * scale, y: uniformScale * scale)
            
            // Draw circles
            for circle in circles {
                let center = CGPoint(x: CGFloat(circle.cx), y: CGFloat(circle.cy))
                let radius = CGFloat(circle.r)
                
                // Choose color based on class
                let color: Color = circle.className == "RedCenter" ? .red : .green
                
                // Draw outer circle
                let strokeWidth = 24.0 / scale // Adjust stroke width based on scale
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )),
                    with: .color(color),
                    lineWidth: strokeWidth
                )
                
                // Draw center point
                let centerRadius = 6.0 / scale
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x - centerRadius,
                        y: center.y - centerRadius,
                        width: centerRadius * 2,
                        height: centerRadius * 2
                    )),
                    with: .color(color)
                )
                
                // Draw crosshair
                let crossSize = 15.0 / scale
                let crossStrokeWidth = 3.0 / scale
                
                // Horizontal line
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: center.x - crossSize, y: center.y))
                        path.addLine(to: CGPoint(x: center.x + crossSize, y: center.y))
                    },
                    with: .color(color),
                    lineWidth: crossStrokeWidth
                )
                
                // Vertical line
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: center.x, y: center.y - crossSize))
                        path.addLine(to: CGPoint(x: center.x, y: center.y + crossSize))
                    },
                    with: .color(color),
                    lineWidth: crossStrokeWidth
                )
            }
        }
    }
}

struct CircleOverlayView: View {
    let circles: [Circle]
    let imageSize: CGSize
    let scale: CGFloat
    let offset: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Apply transformations to match the image
                context.translateBy(x: offset.width, y: offset.height)
                context.scaleBy(x: scale, y: scale)
                
                // Draw circles in image coordinate space
                for circle in circles {
                    let center = CGPoint(x: CGFloat(circle.cx), y: CGFloat(circle.cy))
                    let radius = CGFloat(circle.r)
                    
                    // Choose color based on class
                    let color: Color = circle.className == "RedCenter" ? .red : .green
                    
                    // Adjust stroke width based on scale
                    let strokeWidth = 24.0 / scale
                    let centerRadius = 6.0 / scale
                    let crossSize = 15.0 / scale
                    let crossStrokeWidth = 3.0 / scale
                    
                    // Draw outer circle
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .color(color),
                        lineWidth: strokeWidth
                    )
                    
                    // Draw center point
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - centerRadius,
                            y: center.y - centerRadius,
                            width: centerRadius * 2,
                            height: centerRadius * 2
                        )),
                        with: .color(color)
                    )
                    
                    // Draw crosshair
                    // Horizontal line
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: center.x - crossSize, y: center.y))
                            path.addLine(to: CGPoint(x: center.x + crossSize, y: center.y))
                        },
                        with: .color(color),
                        lineWidth: crossStrokeWidth
                    )
                    
                    // Vertical line
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: center.x, y: center.y - crossSize))
                            path.addLine(to: CGPoint(x: center.x, y: center.y + crossSize))
                        },
                        with: .color(color),
                        lineWidth: crossStrokeWidth
                    )
                }
            }
        }
    }
}

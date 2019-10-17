// MIT License
//
// Copyright (c) 2019 Ralf Ebert
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

public class OverlayActivityIndicator: ActivityIndicator {
    weak var parentView: UIView?
    var overlayView: UIView?

    public init(parentView: UIView) {
        self.parentView = parentView
    }

    public func startActivity() {
        guard let parentView = parentView, self.overlayView == nil else { return }

        let overlayView = UIView()
        self.overlayView = overlayView
        parentView.addSubview(overlayView)

        let bgView = UIView()
        bgView.backgroundColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        bgView.layer.cornerRadius = 10
        overlayView.addSubview(bgView)

        let indicator = UIActivityIndicatorView(frame: .zero)
        indicator.style = .gray
        indicator.sizeToFit()
        indicator.startAnimating()
        bgView.addSubview(indicator)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        bgView.translatesAutoresizingMaskIntoConstraints = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor),

            bgView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            bgView.widthAnchor.constraint(equalToConstant: 65),
            bgView.heightAnchor.constraint(equalToConstant: 65),

            indicator.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
        ])

    }

    public func stopActivity() {
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
    }

}

//
//  FeaturedPackageView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2022 Sileo Team. All rights reserved.
//

import UIKit
import Evander

class FeaturedPackageView: FeaturedBaseView, PackageQueueButtonDataProvider {
    let imageView: PackageIconView
    let titleLabel, authorLabel, versionLabel: UILabel
    
    static let featuredPackageReload = Notification.Name("FeaturedPackageReload")
    
    let repoName: String
    
    let packageButton: PackageQueueButton
    
    let package: String
    
    var separatorView: UIView?
    var separatorHeightConstraint: NSLayoutConstraint?
    
    var icon: String?
    var packageObject: Package?
    
    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let package = dictionary["package"] as? String else {
            return nil
        }
        guard let packageIcon = dictionary["packageIcon"] as? String else {
            return nil
        }
        self.icon = packageIcon
        guard let packageName = dictionary["packageName"] as? String else {
            return nil
        }
        guard let packageAuthor = dictionary["packageAuthor"] as? String else {
            return nil
        }
        guard let repoName = dictionary["repoName"] as? String else {
            return nil
        }
        
        self.package = package
        self.repoName = repoName
        
        imageView = PackageIconView(frame: .zero)
        
        titleLabel = SileoLabelView(frame: .zero)
        authorLabel = UILabel(frame: .zero)
        versionLabel = UILabel(frame: .zero)
        
        packageButton = PackageQueueButton()
        
        separatorView = UIView(frame: .zero)
        
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
        
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        if !packageIcon.isEmpty {
            EvanderNetworking.image(url: packageIcon, size: CGSize(width: 128, height: 128), condition: { [weak self] in self?.icon == packageIcon }, imageView: imageView, fallback: UIImage(named: "Category_tweak"))
        } else {
            imageView.image = UIImage(named: "Category_tweak")
        }
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.text = packageName
        
        authorLabel.text = packageAuthor
        authorLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        authorLabel.textColor = UIColor(red: 143.0/255.0, green: 142.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        
        versionLabel.text = String(format: "%@ · %@", String(localizationKey: "Loading"), repoName)
        versionLabel.textColor = UIColor(red: 143.0/255.0, green: 142.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        versionLabel.font = UIFont.systemFont(ofSize: 11)
        
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, authorLabel, versionLabel])
        titleStackView.spacing = 2
        titleStackView.axis = .vertical
        titleStackView.setCustomSpacing(4, after: authorLabel)
        
        if let buttonText = dictionary["buttonText"] as? String {
            packageButton.overrideTitle = buttonText
        }
        packageButton.viewControllerForPresentation = viewController
        packageButton.setContentHuggingPriority(.required, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleStackView, packageButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.alignment = .center
        self.addSubview(stackView)
        
        stackView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true
        
        let useSeparator = (dictionary["useSeparator"] as? Bool) ?? true
        if useSeparator {
            let separatorView = UIView(frame: .zero)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            separatorView.backgroundColor = .sileoSeparatorColor
            self.addSubview(separatorView)
            
            weak var weakSelf = self
            NotificationCenter.default.addObserver(weakSelf as Any,
                                                   selector: #selector(updateSileoColors),
                                                   name: SileoThemeManager.sileoChangedThemeNotification,
                                                   object: nil)
            
            self.separatorView = separatorView
            
            separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            separatorView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            separatorView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            let separatorHeightConstraint = separatorView.heightAnchor.constraint(equalToConstant: 1)
            
            separatorHeightConstraint.isActive = true
            self.separatorHeightConstraint = separatorHeightConstraint
        }
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = String(format: String(localizationKey: "Package_By_Author"), titleLabel.text ?? "", authorLabel.text ?? "")
        self.accessibilityTraits = .button
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeaturedPackageView.openDepiction))
        tap.delaysTouchesBegan = false
        self.addGestureRecognizer(tap)
        
        viewController.registerForPreviewing(with: self, sourceView: self)
        if #available(iOS 13, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.addInteraction(interaction)
        }
        
        self.reloadPackage()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FeaturedPackageView.reloadPackage),
                                               name: PackageListManager.reloadNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FeaturedPackageView.reloadPackage),
                                               name: FeaturedPackageView.featuredPackageReload,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FeaturedPackageView.reloadPackage),
                                               name: Notification.Name("ShowProvisional"),
                                               object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func updateSileoColors() {
        self.separatorView?.backgroundColor = .sileoSeparatorColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateSileoColors()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        packageButton.tintColor = UINavigationBar.appearance().tintColor
        if let separatorHeightConstraint = self.separatorHeightConstraint {
            separatorHeightConstraint.constant = 1 / (self.window?.screen.scale ?? 1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // If our container has a bigger width, give us a pleasant corner radius
        self.layer.cornerRadius = (self.superview?.bounds.width ?? 0) > self.bounds.width ? 4 : 0
    }
    
    override func depictionHeight(width: CGFloat) -> CGFloat {
        81
    }
    
    override func accessibilityActivate() -> Bool {
        openDepiction(packageButton)
        return true
    }
    
    @objc func openDepiction(_ : Any?) {
        if let package = packageObject {
            self.parentViewController?.navigationController?.pushViewController(NativePackageViewController.viewController(for: package), animated: true)
        } else {
            let title = String(localizationKey: "Package_Unavailable")
            let message = String(format: String(localizationKey: "Package_Unavailable"), repoName)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: String(localizationKey: "OK"), style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))
            self.parentViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.highlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.highlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.highlighted = false
    }
    
    public var highlighted: Bool = false {
        didSet {
            self.backgroundColor = highlighted ? .sileoHighlightColor : nil
        }
    }
    
    @objc public func reloadPackage() {
        self.packageObject = {
            if let holder = PackageListManager.shared.newestPackage(identifier: self.package, repoContext: nil) {
                return holder
            } else if let provisional = CanisterResolver.shared.package(for: self.package) {
                return provisional
            }
            return nil
        }()
        
        if let package = self.packageObject {
            self.versionLabel.text = String(format: "%@ · %@", package.version, self.repoName)
            self.packageButton.package = package
            self.packageButton.isEnabled = true
        } else {
            self.versionLabel.text = String(localizationKey: "Package_Unavailable")
            self.packageButton.package = nil
            self.packageButton.isEnabled = false
        }
        
        updatePaymentInfo()
    }
    
    private func updatePaymentInfo()
    {
        guard let package = self.packageObject, package.commercial, let repo = package.sourceRepo else {
            self.packageButton.paymentInfo = nil
            return
        }
        
        self.packageButton.paymentInfo = PaymentPackageInfo(price: String(localizationKey: "Package_Paid"), purchased: false, available: true)
        
        PaymentManager.shared.getPaymentProvider(for: repo) { error, provider in
                guard error == nil, let provider = provider else {
                    return
                }
// we can always request price for packages even if the repo is not logged in
//                guard provider.isAuthenticated else {
//                    return //we have to re-verify its payment status if the repo is not logged in
//                }

            provider.getPackageInfo(forIdentifier: package.package) { error, info in
                guard error == nil, let info=info, info.available else { return }
                self.packageButton.paymentInfo = info
            }
        }
    }
}

extension FeaturedPackageView: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let package = self.packageObject {
            return NativePackageViewController.viewController(for: package)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.parentViewController?.navigationController?.pushViewController(viewControllerToCommit, animated: false)
    }
}

@available(iOS 13.0, *)
extension FeaturedPackageView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if let package = self.packageObject {
            let packageViewController = NativePackageViewController.viewController(for: package)
            
            let actions = packageViewController.actions()
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                packageViewController
            }, actionProvider: {_ in
                UIMenu(title: "", image: nil, options: .displayInline, children: actions)
            })
        }
        return nil
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if let controller = animator.previewViewController {
            animator.addAnimations {
                self.parentViewController?.show(controller, sender: self)
            }
        }
    }
}

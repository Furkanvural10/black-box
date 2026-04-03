//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 3.04.2026.
//

import UIKit

final class NetworkToastViewController: UIViewController {
    
    
    private var request: NetworkRequest
    private var response: NetworkResponse?
    private let onDismiss: () -> Void
    private var isExpanded = false
    
    private let containerView = UIView()
    private let methodLabel = UILabel()
    private let urlLabel = UILabel()
    private let statusContainer = UIView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    
    private let durationContainer = UIStackView()
    private let durationImageView = UIImageView()
    private let durationLabel = UILabel()
    
    private let sizeContainer = UIStackView()
    private let sizeImageView = UIImageView()
    private let sizeLabel = UILabel()
    
    private let expandedButton = UIButton(type: .system)
    private let divider = UIView()
    private let segmentedController = UISegmentedControl(items: ["Response", "Headers", "Request"])
    
    private var collapsedConstraint: NSLayoutConstraint?
    private var expandedConstraint: NSLayoutConstraint?
    
    private let curlTextView = UITextView()
    
    
    init(request: NetworkRequest, response: NetworkResponse? = nil, onDismiss: @escaping () -> Void) {
        self.request = request
        self.response = response
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        configureScreenGesture()
        setupViews()
    }
    
    private func configureScreenGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTapped(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func handleBackgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            onDismiss()
        }
    }
        
    
    private func setupViews() {
        containerView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 14
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        
        methodLabel.font = .systemFont(ofSize: 11, weight: .bold)
        methodLabel.textColor = .white
        methodLabel.textAlignment = .center
        methodLabel.layer.cornerRadius = 6
        methodLabel.layer.borderWidth = 1
        methodLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        methodLabel.layer.masksToBounds = true
        methodLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(methodLabel)
        
        
        urlLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        urlLabel.textColor = .white
        urlLabel.numberOfLines = 1
        urlLabel.lineBreakMode = .byTruncatingMiddle
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(urlLabel)
        
        statusContainer.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        statusContainer.layer.cornerRadius = 6
        statusContainer.layer.borderWidth = 1
        statusContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusContainer)
        
        
        statusDot.layer.cornerRadius = 3
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusDot)
        
        statusLabel.font = .systemFont(ofSize: 11, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        
        durationImageView.image = UIImage(systemName: "clock")
        durationImageView.tintColor = .lightGray
        durationImageView.contentMode = .scaleAspectFit
        durationImageView.translatesAutoresizingMaskIntoConstraints = false
        
        durationImageView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        durationImageView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        durationLabel.textColor = .lightGray
        
        durationContainer.axis = .horizontal
        durationContainer.spacing = 4
        durationContainer.alignment = .center
        durationContainer.addArrangedSubview(durationImageView)
        durationContainer.addArrangedSubview(durationLabel)
        durationContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(durationContainer)
        
        
        sizeImageView.image = UIImage(systemName: "arrow.down.circle")
        sizeImageView.tintColor = .lightGray
        sizeImageView.contentMode = .scaleAspectFit
        sizeImageView.translatesAutoresizingMaskIntoConstraints = false
        
        sizeImageView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        sizeImageView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        sizeLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        sizeLabel.textColor = .lightGray
        
        sizeContainer.axis = .horizontal
        sizeContainer.spacing = 4
        sizeContainer.alignment = .center
        sizeContainer.addArrangedSubview(sizeImageView)
        sizeContainer.addArrangedSubview(sizeLabel)
        sizeContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sizeContainer)
        
        expandedButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        expandedButton.tintColor = .lightGray
        expandedButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        expandedButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(expandedButton)
        
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = true
        containerView.addSubview(divider)
        
        segmentedController.selectedSegmentIndex = 0
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
        segmentedController.setTitleTextAttributes(attributes, for: .normal)
        segmentedController.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedController.translatesAutoresizingMaskIntoConstraints = false
        segmentedController.isHidden = true
        containerView.addSubview(segmentedController)
        
        curlTextView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        curlTextView.textColor = .white.withAlphaComponent(0.5)
        curlTextView.backgroundColor = .clear
        curlTextView.isEditable = false
        curlTextView.isScrollEnabled = true
        curlTextView.translatesAutoresizingMaskIntoConstraints = false
        curlTextView.isHidden = true
        containerView.addSubview(curlTextView)
    }
    
    private func setupConstraints() {
        collapsedConstraint = statusContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        expandedConstraint = curlTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        
        collapsedConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            methodLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            methodLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            methodLabel.heightAnchor.constraint(equalToConstant: 22),
            methodLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            urlLabel.centerYAnchor.constraint(equalTo: methodLabel.centerYAnchor),
            urlLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 12),
            urlLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            statusContainer.topAnchor.constraint(equalTo: methodLabel.bottomAnchor, constant: 8),
            statusContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusContainer.heightAnchor.constraint(equalToConstant: 22),
            
            statusDot.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            statusDot.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 8),
            statusDot.widthAnchor.constraint(equalToConstant: 6),
            statusDot.heightAnchor.constraint(equalToConstant: 6),
            
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 6),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -8),
            
            durationContainer.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            durationContainer.leadingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: 16),
            
            sizeContainer.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            sizeContainer.leadingAnchor.constraint(equalTo: durationContainer.trailingAnchor, constant: 16),
            
            expandedButton.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            expandedButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            expandedButton.widthAnchor.constraint(equalToConstant: 24),
            expandedButton.heightAnchor.constraint(equalToConstant: 24),
            
            divider.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 8),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            segmentedController.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 1),
            segmentedController.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            segmentedController.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            curlTextView.topAnchor.constraint(equalTo: segmentedController.bottomAnchor, constant: 8),
            curlTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            curlTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            curlTextView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    
    private func updateContent() {
        methodLabel.text = request.method
        methodLabel.backgroundColor = methodColor(request.method).withAlphaComponent(0.2)
        methodLabel.layer.borderColor = methodColor(request.method).cgColor
        methodLabel.textColor = methodColor(request.method)
        
        urlLabel.text = request.url.absoluteString
        
        updateTextView()
        
        if let response = response {
            statusDot.backgroundColor = statusColor(response.statusCode)
            statusLabel.text = "\(response.statusCode)"
            statusLabel.textColor = .white
            
            
            statusContainer.isHidden = false
            
            durationLabel.text = response.formattedDuration
            durationContainer.isHidden = false
            
            if let size = response.formattedDataSize {
                sizeLabel.text = size
                sizeContainer.isHidden = false
            } else {
                sizeContainer.isHidden = true
            }
        } else {
            statusContainer.isHidden = true
            durationContainer.isHidden = true
            sizeContainer.isHidden = true
        }
    }
    
    @objc private func segmentChanged() {
        updateTextView()
    }
    
    private func updateTextView() {
        switch segmentedController.selectedSegmentIndex {
        case 0: // Response
            if let response = response, let json = response.prettyJSON {
                curlTextView.text = json
            } else {
                curlTextView.text = "No response body"
            }
        case 1: // Headers
            var text = ""
            if let response = response {
                text += "[Response Headers]\n"
                text += response.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            }
            text += "\n\n[Request Headers]\n"
            text += request.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            curlTextView.text = text
        case 2: // Request
            curlTextView.text = request.toCURL()
        default:
            break
        }
    }
    
    func update(request: NetworkRequest, response: NetworkResponse?) {
        self.request = request
        self.response = response
        updateContent()
    }
    
    @objc private func toggleExpand() {
        isExpanded.toggle()
        NetworkToastManager.shared.setExpanded(isExpanded)
        
        UIView.animate(withDuration: 0.3) {
            self.expandedButton.setImage(
                UIImage(systemName: self.isExpanded ? "chevron.up" : "chevron.down"),
                for: .normal
            )
            self.divider.isHidden = !self.isExpanded
            self.segmentedController.isHidden = !self.isExpanded
            self.curlTextView.isHidden = !self.isExpanded
            
            if self.isExpanded {
                self.collapsedConstraint?.isActive = false
                self.expandedConstraint?.isActive = true
            } else {
                self.expandedConstraint?.isActive = false
                self.collapsedConstraint?.isActive = true
            }
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func methodColor(_ method: String) -> UIColor {
        switch method {
        case "GET": return .systemBlue
        case "POST": return .systemGreen
        case "PUT": return .systemOrange
        case "DELETE": return .systemRed
        case "PATCH": return .systemPurple
        default: return .systemGray
        }
    }
    
    private func statusColor(_ code: Int) -> UIColor {
        switch code {
        case 200..<300: return .systemGreen
        case 300..<400: return .systemBlue
        case 400..<500: return .systemOrange
        case 500..<600: return .systemRed
        default: return .systemGray
        }
    }
}

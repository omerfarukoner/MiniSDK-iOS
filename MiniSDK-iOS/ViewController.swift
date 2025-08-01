import UIKit

class ViewController: UIViewController {
  private lazy var testButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Test Button", for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    button.backgroundColor = .systemBlue
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 8
    button.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground

    view.addSubview(testButton)

    NSLayoutConstraint.activate([
      testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      testButton.widthAnchor.constraint(equalToConstant: 200),
      testButton.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  @objc private func testButtonTapped() {
    let payload = ["screen": "Main"]
    MiniSDK.shared.trackEvent(name: "button_clicked", payload: payload)
  }
}

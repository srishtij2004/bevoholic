//
//  HeaderViewController.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 3/9/26.
//

import UIKit

class HeaderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
    }

    func setupHeader() {
        if shouldShowMainMenuButton {
            let home = UIBarButtonItem(
                title: "Menu",
                style: .plain,
                target: self,
                action: #selector(openMainMenu)
            )
            home.tintColor = .white
            navigationItem.leftBarButtonItem = home
        } else {
            navigationItem.leftBarButtonItem = nil
        }

        let settings = UIBarButtonItem(
            image: UIImage(systemName: "person.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        settings.tintColor = .white
        navigationItem.rightBarButtonItem = settings

        let headerLogo = UIImageView(image: UIImage(named: "Logo"))
        headerLogo.contentMode = .scaleAspectFit
        headerLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLogo)

        NSLayoutConstraint.activate([
            headerLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            headerLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerLogo.widthAnchor.constraint(equalToConstant: 250),
            headerLogo.heightAnchor.constraint(equalToConstant: 100)   
        ])
    }

    var shouldShowMainMenuButton: Bool {
        !(self is HomeViewController)
    }

    @objc func openSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    @objc func openMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
}

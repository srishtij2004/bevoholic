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

    @objc func openSettings() {
        performSegue(withIdentifier: "showSettings", sender: self)
    }
}

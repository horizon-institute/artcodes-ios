/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import ArtcodesScanner
import UIKit
import Tabman
import Pageboy

class ExperienceEditViewController: TabmanViewController, PageboyViewControllerDataSource, TMBarDataSource {
    
    private let viewControllers: [ExperienceEditBaseViewController]
    private let account: Account
    var experience: Experience
    private let fab = UIButton()
    
    init(experience: Experience, account: Account) {
        self.experience = experience.clone()
        self.account = account
        viewControllers = [ExperienceEditInfoViewController(),
                           AvailabilityListViewController(),
                           ActionListViewController()]
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(save))
        
        // Create bar
        let bar = TMBar.ButtonBar()
        bar.systemBar().backgroundStyle = .flat(color: UIColor(hex6: 0x324A5E))
        bar.backgroundColor = UIColor(hex6: 0x324A5E)
        bar.indicator.tintColor = .white
        bar.buttons.customize() { button in
            button.tintColor = .white
            button.selectedTintColor = .white
        }
        bar.layout.transitionStyle = .snap
        
        bar.layout.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Add to view
        addBar(bar, dataSource: self, at: .top)
        
        let deleteButton = UIBarButtonItem(image: UIImage(named: "ic_delete_18pt"), style: .plain, target: self, action: #selector(deleteExperience))
        deleteButton.tintColor = .red
        
        setToolbarItems([
            deleteButton,
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        ], animated: false)
                
        fab.translatesAutoresizingMaskIntoConstraints = false
        fab.setImage(UIImage(named: "ic_add"), for: .normal)
        fab.backgroundColor = UIColor(hex6: 0x295A9E)
        fab.tintColor = UIColor.white
        fab.layer.shadowRadius = 3
        fab.layer.shadowOpacity = 0.2
        fab.layer.shadowOffset = CGSize(width: 0, height: 2)
        fab.layer.cornerRadius = 28
        fab.isHidden = true
        fab.addTarget(self, action: #selector(add), for: .touchUpInside)
        fab.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fab)
        view.bringSubviewToFront(fab)
        
        NSLayoutConstraint.activate([
            fab.widthAnchor.constraint(equalToConstant: 56),
            fab.heightAnchor.constraint(equalToConstant: 56), 
            fab.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -18),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 24)
        ])
        print(view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.toolbar.barTintColor = .clear
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.barStyle = .black
        navigationController?.setToolbarHidden(false, animated: animated)
        
        view.bringSubviewToFront(fab)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = viewControllers[index].title ?? "Page \(index)"
        return TMBarItem(title: title)
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                             willScrollToPageAt index: Int,
                                             direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController, willScrollToPageAt: index, direction: direction, animated: animated)
        let hide = !viewControllers[index].addEnabled
        if hide != fab.isHidden
        {
            if hide
            {
                fab.circleHide(speed: 0.1)
            }
            else
            {
                fab.circleReveal(speed: 0.1)
            }
        }
    }
    
    @objc func cancel()
    {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func add()
    {
        viewControllers[currentIndex ?? 0].add()
    }
    
    @objc func save()
    {
        view.endEditing(true)
        
        // TODO experience.json = edited.json
        account.saveExperience(experience: experience)
        
        if var viewControllers = navigationController?.viewControllers
        {
            // TODO Replace ExperienceViewController where experience.id = id?
            if !(viewControllers[ viewControllers.count - 2 ] is ExperienceViewController)
            {
                viewControllers.insert(ExperienceViewController(experience: experience), at: viewControllers.count - 1)
                navigationController?.viewControllers = viewControllers
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func deleteExperience()
    {
        let refreshAlert = UIAlertController(title: "Delete?", message: "The experience will be lost for good", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction!) in
            if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
            {
                appDelegate.server.deleteExperience(experience: self.experience)
                self.navigationController?.popToRootViewController(animated: true)
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        present(refreshAlert, animated: true, completion: nil)
    }
}

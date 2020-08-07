//
//  OnboardingPageController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 05/09/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class OnboardingPageController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setViewControllers([getStepOne()], direction: .forward, animated: false, completion: nil)
        view.backgroundColor = .darkGray
        // Do any additional setup after loading the view.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let VC = viewController as? OnboardingViewController else { return nil }
        
        if VC.view.backgroundColor == .systemBlue {
            return getStepTwo()
        } else {
            return nil
        }
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let VC = viewController as? OnboardingViewController else { return nil }
        
        if VC.view.backgroundColor == .systemRed {
            return getStepOne()
        } else {
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 2
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func getStepOne() -> OnboardingViewController {
        let viewController = storyboard!.instantiateViewController(withIdentifier: "OnboardingView") as! OnboardingViewController
        viewController.customLabel.text = "1"
        
        return viewController
    }
    
    func getStepTwo() -> OnboardingViewController {
        let viewController = storyboard!.instantiateViewController(withIdentifier: "OnboardingView") as! OnboardingViewController
        viewController.customLabel.text = "2"
        
        return viewController
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

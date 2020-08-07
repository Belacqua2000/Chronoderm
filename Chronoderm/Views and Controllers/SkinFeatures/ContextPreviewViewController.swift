//
//  ContextPreviewViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 01/10/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class ContextPreviewViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    let imageView = UIImageView()
    
    override func loadView() {
        view = imageView
    }
    
    init(entry: Entry) {
        super.init(nibName: nil, bundle: nil)

        // Set up our image view and display the pupper
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        let attachment = entry.image?.anyObject() as! Attachment
        imageView.image = UIImage(data: attachment.fullImage!.fullImage!)

        // By setting the preferredContentSize to the image size,
        // the preview will have the same aspect ratio as the image
        preferredContentSize = UIImage(data: (attachment.fullImage?.fullImage)!)!.size
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

//
//  DrawingViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 23/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit
import PencilKit
#if !targetEnvironment(macCatalyst)
class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupCanvas()
        setupTools()
    }
    
    var image: UIImage!
    @IBOutlet var imageView: UIImageView!
    var toolPicker: PKToolPicker!
    var canvas: PKCanvasView!
    
    func setupCanvas() {
        let bounds = view.bounds
        canvas = PKCanvasView(frame: bounds)
        view.addSubview(canvas)
        canvas.tool = PKInkingTool(.pen, color: .black, width: 30)
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
    }
    
    func setupTools() {
        if #available(iOS 14.0, *) {
            //   toolPicker = PKToolPicker()
        } else {
            // Set up the tool picker, using the window of our parent because our view has not
            // been added to a window yet.
            let window = presentingViewController?.view.window
            toolPicker = PKToolPicker.shared(for: window!)
        }
        
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        toolPicker.addObserver(self)
        //updateLayout(for: toolPicker)
        canvas.becomeFirstResponder()
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
#endif

//
//  ChooseSourceController.swift
//  VisionDetection
//
//  Created by Alexander Chulanov on 10/13/18.
//  Copyright © 2018 Willjay. All rights reserved.
//

import UIKit

class ChooseSourceController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var videoURL: URL!
    
    override func viewDidLoad() {
    }
    
    func showVideoLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        imagePicker.modalPresentationStyle = .overCurrentContext
        imagePicker.mediaTypes = ["public.movie"]
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func showVideo(index: Int) {
        
    }
    
    func showFaceReplaceController(url: URL) {
        videoURL = url
        performSegue(withIdentifier: "showVideo", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let videoController = segue.destination as? VideoController else { return }
        videoController.videoURL = videoURL
    }
}

extension ChooseSourceController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) {
            guard let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
            self.showFaceReplaceController(url: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
        }
    }
}

extension ChooseSourceController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            showVideoLibrary()
        default:
            showVideo(index: indexPath.row)
        }
    }
}

extension ChooseSourceController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cellTitle: String
        
        switch indexPath.row {
        case 0:
            cellTitle = "Video Library"
        case 1:
            cellTitle = "From Parise with love"
        default:
            cellTitle = ""
        }
        
        cell?.textLabel?.text = cellTitle
        
        return cell!
    }
    
    
}

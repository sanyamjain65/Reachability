//
//  CallScreen.swift
//  PatchFramework
//
//  Created by Sanyam Jain on 25/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import UIKit

public class CallScreen: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let nibName = "CallScreen"
    var contentView: UIView!
    
    public override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        setUpView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // For use in Interface Builder
        super.init(coder: aDecoder)
        setUpView()
    }
    
    public func setUpView() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        addSubview(contentView)
        
        contentView.center = self.center
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true

    }
    
    @IBAction func close() {
        self.removeFromSuperview()
    }

}

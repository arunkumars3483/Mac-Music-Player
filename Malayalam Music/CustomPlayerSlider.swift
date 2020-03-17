//
//  CustomPlayerSlider.swift
//  Malayalam Music
//
//  Created by Arun kumar on 17/03/20.
//  Copyright © 2020 qburst. All rights reserved.
//

import Cocoa

class CustomPlayerSlider: NSSlider {
    
    public var isDragging = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        super.mouseUp(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        
    }
    
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        super.mouseDown(with: event)
    }
    
}

//
//  ViewController.swift
//  Malayalam Music
//
//  Created by Arun kumar on 17/03/20.
//  Copyright © 2020 qburst. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var playerProgress: NSProgressIndicator!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var playerSlider: CustomPlayerSlider!
    
    @IBOutlet weak var musicTableView: NSTableView!
    @IBOutlet weak var musicName: NSTextField!
    @IBOutlet weak var nowTime: NSTextField!
    @IBOutlet weak var endTime: NSTextField!
    
    
    
    var player: AVPlayer?
    var timeObserver: Any?
    var currentIndex = 0
    var musicfiles:[Dictionary<String, Any>] = []
    
    var seekInitiated = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let path = Bundle.main.path(forResource: "musicdata", ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                  let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                  if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let music = jsonResult["files"] as? [Any] {
                    musicfiles = music as? [Dictionary] ?? []
                    print(musicfiles[0]["album"] ?? "")
                  }
              } catch {
              }
        }
        
        musicTableView.delegate = self
        musicTableView.dataSource = self
        
        musicTableView.doubleAction = #selector(handleDoubleClick)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.init(rawValue: "play"), object: nil, queue: nil) { (notification) in
            self.playButtonClicked(self.playButton)
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.init(rawValue: "pause"), object: nil, queue: nil) { (notification) in
            self.pauseButtonClicked(self.pauseButton)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.init(rawValue: "next"), object: nil, queue: nil) { (notification) in
            self.nextMusic()
        }
        
    }
    
    override func viewWillAppear() {
        playMusic(url: "https://mallusongsdownload.info" + (self.musicfiles[currentIndex]["url"] as! String))
    }
    
    func nextMusic(){
        playerDidFinishPlaying()
    }
    
    func playMusic(url: String){
        if(timeObserver != nil){
            player?.removeTimeObserver(timeObserver)
        }

        
        let url = URL(string: url)
        print(url)
        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        musicName.stringValue = (self.musicfiles[currentIndex]["name"] as! String) + " (" + (self.musicfiles[currentIndex]["album"] as! String) + ")"
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsedTime in
            self.updateSlider(elapsedTime: elapsedTime)
        })
    }
    
    @objc func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        if (currentIndex + 1) != self.musicfiles.count{
            currentIndex = currentIndex + 1
            playMusic(url: "https://mallusongsdownload.info" + (self.musicfiles[currentIndex]["url"] as! String))
            player!.play()
        }
    }
    
    @objc func handleDoubleClick() {
        let clickedRow = musicTableView.clickedRow
        currentIndex = clickedRow
        playMusic(url: "https://mallusongsdownload.info" + (self.musicfiles[clickedRow]["url"] as! String))
        player!.play()
    }
    
    func updateSlider(elapsedTime: CMTime) {
        if !playerSlider.isDragging{
            let playerDuration = playerItemDuration()
            if CMTIME_IS_INVALID(playerDuration) {
                playerSlider.minValue = 0.0
                return
            }
            
            let duration = Float(CMTimeGetSeconds(playerDuration))
            if duration.isFinite && duration > 0 {
                
                let now = Float(CMTimeGetSeconds(elapsedTime))
                nowTime.stringValue = String(  Int((Int(now) % 3600) / 60)  ) + ":" + String( ( Int( (Int(now) % 3600) ) % 60) )
                endTime.stringValue = String(  Int((Int(duration) % 3600) / 60)  ) + ":" +  String( ( Int( (Int(duration) % 3600) ) % 60) )
                playerSlider.minValue = 0.0
                playerSlider.maxValue = Double(duration)
                let time = Float(CMTimeGetSeconds(elapsedTime))
                playerSlider.doubleValue = Double(time)
            }
        }
        
        
    }
    
    private func playerItemDuration() -> CMTime {
        let thePlayerItem = player?.currentItem
        if thePlayerItem?.status == .readyToPlay {
            return thePlayerItem!.duration
        }
        return .invalid
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        let event = NSApplication.shared.currentEvent

        if event?.type == NSEvent.EventType.leftMouseUp {
            if(player?.currentItem != nil){
                
                player?.pause()
                
                player?.seek(to: CMTime.init(seconds: playerSlider.doubleValue, preferredTimescale: .max))
                
                player?.play()
                
                playerSlider.isDragging = false
            }
            
        }
    }
    
    
    @IBAction func playButtonClicked(_ sender: Any) {
        
        if player?.rate == 0
        {
            player!.play()
            
        } else {
            player!.pause()
            
        }
    }
    
    @IBAction func pauseButtonClicked(_ sender: Any) {
        player!.pause()
    }
    
    @IBAction func stopButtonClicked(_ sender: Any) {
        player!.pause()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "musicCell"), owner: nil) as? MusicCellView {
          
            let music = self.musicfiles[row]
            
            cell.musicLabel.stringValue = (music["name"] as! String).replacingOccurrences(of: ".ws.mp3", with: "")
            cell.albumLabel.stringValue = (music["album"] as! String) + " (" + (music["year"] as! String) + ")"
            
          return cell
        }
        return nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        self.musicfiles.count
    }
    
    
    
}


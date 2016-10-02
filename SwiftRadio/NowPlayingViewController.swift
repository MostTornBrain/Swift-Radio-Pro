//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//
//  Modified October 2015 to use StormyProductions RadioKit for improved stream handling
//  NOTE: RadioKit is an streaming library that requires a license key if used
//       in a product.  For more information, see: http://www.stormyprods.com/products/radiokit.php


import UIKit
import MediaPlayer

//*****************************************************************
// Protocol
// Updates the StationsViewController when the track changes
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(track: Track)
    func artworkDidUpdate(track: Track)
    func trackPlayingToggled(track: Track)
}

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rewButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var slider = UISlider()
    @IBOutlet weak var bufferView: BufferView!
    @IBOutlet weak var nowPlayingImageView: Visualizer!
    
    var currentStation: RadioStation!
    var downloadTask: URLSessionDownloadTask?
    var iPhone4 = false
    var justBecameActive = false
    var newStation = true
    let radioPlayer = Player.radio
    var track: Track!
    var mpVolumeSlider = UISlider()
    
    var rewOrFFTimer = NSTimer()
    var bufferViewTimer = NSTimer()
    var audioVisualTimer = NSTimer()
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup handoff functionality - GH
        setupUserActivity()
        
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = currentStation.stationName
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Setup RadioKit library
        setupPlayer()
        
        // Notification for when app becomes active
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.didBecomeActiveNotificationReceived),
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        
        // Notification for MediaPlayer metadata updated
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.metadataUpdated),
            name: Notification.Name.MPMoviePlayerTimedMetadataUpdated,
            object: nil)
        
        // Notification for AVAudioSession Interruption (e.g. Phone call)
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.sessionInterrupted),
            name: Notification.Name.AVAudioSessionInterruption,
            object: AVAudioSession.sharedInstance())
        
        // Check for station change
        if newStation {
            track = Track()
            stationDidChange()
        } else {
            updateLabels()
            albumImageView.image = track.artworkImage
            
            if !track.isPlaying {
                pausePressed()
            }
        }
        
        // Setup slider
        setupVolumeSlider()
        
        startBufferViewThread()
    }
    
    func didBecomeActiveNotificationReceived() {
        // View became active
        updateLabels()
        justBecameActive = true
        updateAlbumArtwork()
    }
    
    deinit {
        // Be a good citizen
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name.MPMoviePlayerTimedMetadataUpdated,
            object: nil)
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name.AVAudioSessionInterruption,
            object: AVAudioSession.sharedInstance())
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupPlayer() {
        // We only need to perform some setup operations once for the lifetime of the app
        struct Onceler{
            static var doOnce = true
        }
        
        if (Onceler.doOnce){
            Onceler.doOnce = false

            //TODO: Enter you RadioKit license key information here.
            radioPlayer.authenticateLibraryWithKey1(0x1, andKey2: 0x02)
            radioPlayer.setBufferWaitTime(15);
            radioPlayer.setDataTimeout(10);
            
            if DEBUG_LOG {
                print("RadioKit version: \(radioPlayer.version())")
            }
        }
        
        // We need to set the delegate each time we load a new view controller as it could be a different controller each time.
        radioPlayer.delegate = self
        nowPlayingImageView.radioKit = radioPlayer
        audioVisualTimer = NSTimer.scheduledTimerWithTimeInterval(1.0/15.0, target:self, selector:"audioVisualizationThread", userInfo:nil, repeats:true)


        radioPlayer.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        radioPlayer.view.sizeToFit()
        radioPlayer.movieSourceType = MPMovieSourceType.streaming
        radioPlayer.isFullscreen = false
        radioPlayer.shouldAutoplay = true
        radioPlayer.prepareToPlay()
        radioPlayer.controlStyle = MPMovieControlStyle.none
    }
  
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
            if (uiview.description as NSString).range(of: "MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
        
        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, for: .normal)
        
    }
    
    func stationDidChange() {
        radioPlayer.stopStream()
        
        radioPlayer.setStreamUrl(currentStation.stationStreamURL, isFile: false)
        radioPlayer.startStream()
        
        updateLabels(statusMessage: "Loading Station...")
        
        // songLabel animate
        songLabel.animation = "flash"
        songLabel.repeatCount = 3
        songLabel.animate()
        
        resetAlbumArtwork()
        
        track.isPlaying = true
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func playPressed() {
        track.isPlaying = true
        playButtonEnable(false)
        radioPlayer.startStream()
        updateLabels()
        
        // songLabel Animation
        songLabel.animation = "flash"
        songLabel.animate()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
    }
    
    @IBAction func pausePressed() {
        track.isPlaying = false
        
        playButtonEnable()
        
        radioPlayer.pauseStream()
        updateLabels(statusMessage: "Station Paused...")
        nowPlayingImageView.stopAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
    }
    
    @IBAction func volumeChanged(_ sender:UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    func rewind()
    {
        radioPlayer.rewind(10)		  // Rewind 10 seconds
        dispatch_async(dispatch_get_main_queue(), {
            self.updateAudioButtons()
        })
    }
    
    @IBAction func rewindDown()
    {
        rewind()
        rewOrFFTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target:self, selector:"rewind", userInfo:nil, repeats:true)
    }
    
    
    @IBAction func rewindUp()
    {
        rewOrFFTimer.invalidate();
    }
    
    func fastForward()
    {
        radioPlayer.fastForward(10)
        dispatch_async(dispatch_get_main_queue(), {
            self.updateAudioButtons()
        })
    }
    
    
    @IBAction func fastForwardDown()
    {
        fastForward()
        rewOrFFTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target:self, selector:"fastForward", userInfo:nil, repeats:true)
    }
    
    
    @IBAction func fastForwardUp()
    {
        rewOrFFTimer.invalidate()
    }
    
    
    func bufferVisualThread()
    {
        bufferView.bufferSizeSRK = radioPlayer.maxBufferSize()
        bufferView.bufferCountSRK = radioPlayer.currBufferUsage()
        bufferView.currBuffPtr = radioPlayer.currBufferPlaying()
        bufferView.bufferByteOffset = radioPlayer.bufferByteOffset()
        
        dispatch_async(dispatch_get_main_queue(), {
            self.bufferView.setNeedsDisplay()})
    }

    func startBufferViewThread()
    {
        bufferViewTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target:self, selector:"bufferVisualThread", userInfo:nil, repeats:true)
    }
    
    
    func stopBufferViewThread()
    {
        bufferViewTimer.invalidate()
    }
    
    func audioVisualizationThread()
    {
        nowPlayingImageView.updateData()
    }
    
    //*****************************************************************
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func optimizeForDeviceSize() {
        
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height
        
        if deviceHeight == 480 {
            iPhone4 = true
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }
    
    func updateLabels(statusMessage: String = "") {
        
        if statusMessage != "" {
            // There's a an interruption or pause in the audio queue
            songLabel.text = statusMessage
            artistLabel.text = currentStation.stationName
            
        } else {
            // Radio is (hopefully) streaming properly
            if track != nil {
                songLabel.text = track.title
                artistLabel.text = track.artist
            }
        }
        
        // Hide station description when album art is displayed or on iPhone 4
        if track.artworkLoaded || iPhone4 {
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
            stationDescLabel.text = currentStation.stationDesc
        }
    }
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            track.isPlaying = false
        } else {
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            track.isPlaying = true
        }
        updateAudioButtons()
    }

    func updateAudioButtons() {
            // Check if the stream is currently playing.  If so, adjust the play control buttons
            if (track.isPlaying){
                    rewButton.enabled = true
                    
                    if (radioPlayer.isFastForwardAllowed(10)){
                        ffButton.enabled = true
                    }else{
                        ffButton.enabled = false
                    }
            }else{
                rewButton.enabled = false
                ffButton.enabled = false
            }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIViewContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: UIButtonType.custom)
        barButton.frame = CGRect(x: 0,y: 0,width: 40,height: 40);
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
        
    }
    
    func startNowPlayingAnimation() {
        nowPlayingImageView.startAnimating()
    }

    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    func resetAlbumArtwork() {
        track.artworkLoaded = false
        track.artworkURL = currentStation.stationImageURL
        updateAlbumArtwork()
        stationDescLabel.isHidden = false
    }
    
    func updateAlbumArtwork() {
        track.artworkLoaded = false
        if track.artworkURL.range(of: "http") != nil {
            
            // Hide station description
            DispatchQueue.main.async(execute: {
                //self.albumImageView.image = nil
                self.stationDescLabel.isHidden = false
            })
            
            // Attempt to download album art from an API
            if let url = URL(string: track.artworkURL) {
                
                self.downloadTask = self.albumImageView.loadImageWithURL(url: url) { (image) in
                    
                    // Update track struct
                    self.track.artworkImage = image
                    self.track.artworkLoaded = true
                    
                    // Turn off network activity indicator
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    // Animate artwork
                    self.albumImageView.animation = "wobble"
                    self.albumImageView.duration = 2
                    self.albumImageView.animate()
                    self.stationDescLabel.isHidden = true

                    // Update lockscreen
                    self.updateLockScreen()
                    
                    // Call delegate function that artwork updated
                    self.delegate?.artworkDidUpdate(track: self.track)
                }
            }
            
            // Hide the station description to make room for album art
            if track.artworkLoaded && !self.justBecameActive {
                self.stationDescLabel.isHidden = true
                self.justBecameActive = false
            }
            
        } else if track.artworkURL != "" {
            // Local artwork
            self.albumImageView.image = UIImage(named: track.artworkURL)
            track.artworkImage = albumImageView.image
            track.artworkLoaded = true
            
            // Call delegate function that artwork updated
            self.delegate?.artworkDidUpdate(track: self.track)
            
        } else {
            // No Station or API art found, use default art
            self.albumImageView.image = UIImage(named: "albumArt")
            track.artworkImage = albumImageView.image
        }
        
        // Force app to update display
        self.view.setNeedsDisplay()
    }

    // Call LastFM or iTunes API to get album art url
    
    func queryAlbumArt() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Construct either LastFM or iTunes API call URL
        let queryURL: String
        if useLastFM {
            queryURL = String(format: "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=%@&artist=%@&track=%@&format=json", apiKey, track.artist, track.title)
        } else {
            queryURL = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", track.artist, track.title)
        }
        
        let escapedURL = queryURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // Query API
        DataManager.getTrackDataWithSuccess(queryURL: escapedURL!) { (data) in
            
            if kDebugLog {
                print("API SUCCESSFUL RETURN")
                print("url: \(escapedURL!)")
            }
            
            let json = JSON(data: data! as Data)
            
            if useLastFM {
                // Get Largest Sized LastFM Image
                if let imageArray = json["track"]["album"]["image"].array {
                    
                    let arrayCount = imageArray.count
                    let lastImage = imageArray[arrayCount - 1]
                    
                    if let artURL = lastImage["#text"].string {
                        
                        // Check for Default Last FM Image
                        if artURL.range(of: "/noimage/") != nil {
                            self.resetAlbumArtwork()
                            
                        } else {
                            // LastFM image found!
                            self.track.artworkURL = artURL
                            self.track.artworkLoaded = true
                            self.updateAlbumArtwork()
                        }
                        
                    } else {
                        self.resetAlbumArtwork()
                    }
                } else {
                    self.resetAlbumArtwork()
                }
            
            } else {
                // Use iTunes API. Images are 100px by 100px
                if let artURL = json["results"][0]["artworkUrl100"].string {
                    
                    if kDebugLog { print("iTunes artURL: \(artURL)") }
                    
                    self.track.artworkURL = artURL
                    self.track.artworkLoaded = true
                    self.updateAlbumArtwork()
                } else {
                    self.resetAlbumArtwork()
                }
            }
            
        }
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "InfoDetail" {
            let infoController = segue.destination as! InfoDetailViewController
            infoController.currentStation = currentStation
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let songToShare = "I'm listening to \(track.title) on \(currentStation.stationName) via Swift Radio Pro"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, track.artworkImage!], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    override func remoteControlReceived(with receivedEvent: UIEvent?) {
        super.remoteControlReceived(with: receivedEvent)
        
        if receivedEvent!.type == UIEventType.remoteControl {
            
            switch receivedEvent!.subtype {
            case .remoteControlPlay:
                playPressed()
            case .remoteControlPause:
                pausePressed()
            default:
                break
            }
        }
    }
    
    // MARK Stormy RadioKit (SRK) protocol handlers
    
    //*****************************************************************
    // MARK: - MetaData Updated Notification
    //*****************************************************************
    
    func SRKMetaChanged()
    {
        if(radioPlayer.currTitle != nil)
        {
            let metaData = radioPlayer.currTitle as String
            
            var stringParts = [String]()
            if metaData.range(of: " - ") != nil {
                stringParts = metaData.components(separatedBy: " - ")
            } else {
                stringParts = metaData.components(separatedBy: "-")
            }
            
            // Set artist & songvariables
            let currentSongName = track.title
            track.artist = stringParts[0]
            track.title = stringParts[0]
            
            if stringParts.count > 1 {
                track.title = stringParts[1]
            }
            
            if track.artist == "" && track.title == "" {
                track.artist = currentStation.stationDesc
                track.title = currentStation.stationName
            }
            
            DispatchQueue.main.async(execute: {
                
                if currentSongName != self.track.title {
                    
                    if kDebugLog {
                        print("METADATA artist: \(self.track.artist) | title: \(self.track.title)")
                    }
                    
                    // Update Labels
                    self.artistLabel.text = self.track.artist
                    self.songLabel.text = self.track.title
                    self.updateUserActivityState(self.userActivity!)
                    
                    // songLabel animation
                    self.songLabel.animation = "zoomIn"
                    self.songLabel.duration = 1.5
                    self.songLabel.damping = 1
                    self.songLabel.animate()
                    
                    // Update Stations Screen
                    self.delegate?.songMetaDataDidUpdate(track: self.track)
                    
                    // Query API for album art
                    self.resetAlbumArtwork()
                    self.queryAlbumArt()
                    self.updateLockScreen()
                    
                }
            })
        }
    }
    
    //*****************************************************************
    // MARK: - AVAudio Sesssion Interrupted
    //*****************************************************************
    
    // Example code on handling AVAudio interruptions (e.g. Phone calls)
    func sessionInterrupted(notification: NSNotification) {
        if let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber{
            if let type = AVAudioSessionInterruptionType(rawValue: typeValue.uintValue){
                if type == .began {
                    print("interruption: began")
                    // Add your code here
                } else{
                    print("interruption: ended")
                    // Add your code here
                }
            }
        }
    }
    
    func SRKConnecting()
    {
        dispatch_async(dispatch_get_main_queue(), {
            self.updateLabels("Connecting to Station...")
        })
    }
    
    func SRKIsBuffering()
    {
        dispatch_async(dispatch_get_main_queue(), {
            self.updateLabels("Buffering...")
        })
    }
    
    func SRKPlayStarted()
    {
        radioPlayer.enableLevelMetering() // Must make this call before using the audio gain visualizer

        dispatch_async(dispatch_get_main_queue(), {
            self.updateLabels()
            self.playButtonEnable(false)
        })
    }
    
    func SRKPlayStopped()
    {
        dispatch_async(dispatch_get_main_queue(), {
            self.playButtonEnable(true)})
    }
    
    func SRKPlayPaused()
    {
        dispatch_async(dispatch_get_main_queue(), {
            self.playButtonEnable(true)
            self.updateLabels("Station Paused...")
        })
    }
    
    func SRKNoNetworkFound()
    {
        
    }


    //*****************************************************************
    // MARK: - Handoff Functionality - GH
    //*****************************************************************
    
    func setupUserActivity() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb ) //"com.graemeharrison.handoff.googlesearch" //NSUserActivityTypeBrowsingWeb
        userActivity = activity
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        userActivity?.becomeCurrent()
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        super.updateUserActivityState(activity)
    }
}

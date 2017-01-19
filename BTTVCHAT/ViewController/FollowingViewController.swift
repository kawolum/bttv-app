//
//  FollowingViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/17/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class FollowingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var channels = [Channel]()
    
    let slideRightAnimationController = SlideRightAnimationController()
    let slideLeftAnimationController = SlideLeftAnimationController()
    let swipeInteractionController = SwipeInteractionController()
    
    var channelsAPIURLStringTemplate0 = "https://api.twitch.tv/kraken/streams/followed?limit=50&stream_type=live&offset=0"
    var channelsAPIURLStringTemplate1 = "https://api.twitch.tv/kraken/streams/followed?limit=75&stream_type=live&offset="
    var offset = 0
    let offsetInc = 50
    let overlap = 25
    var loadingChannels = false
    var got0 = false
    
    let headerAcceptKey = "Accept"
    let headerAcceptValue = "application/vnd.twitchtv.v5+json"
    let headerClientIDKey = "Client-ID"
    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    var selectedIndex = 0;
    var channelNames = Set<String>()
    var refreshControl = UIRefreshControl()
    
    var cellImageViewWidth: Int?
    var cellImageViewHeight: Int?
    
    let strokeTextAttributes = [NSForegroundColorAttributeName : UIColor.white, NSStrokeColorAttributeName : UIColor.black, NSStrokeWidthAttributeName : -1] as [String : Any]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        let imageWidthCGfloat = tableView.frame.size.width - 20
        let imageHeightCGfloat = imageWidthCGfloat * 9 / 16
        
        cellImageViewWidth = Int(ceil(imageWidthCGfloat))
        cellImageViewHeight = Int(ceil(imageHeightCGfloat))
        
        tableView.rowHeight = ceil(imageHeightCGfloat + 10)
        
        getChannels(){ getCount in
            print(getCount)
            if getCount > 0 {
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
                self.downloadImages(count: getCount)
            }
        }
        
        self.refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        if !loadingChannels {
            channels.removeAll()
            offset = 0
            channelNames.removeAll()
            getChannels(){ getCount in
                if getCount > 0 {
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                        refreshControl.endRefreshing()
                    }
                    self.downloadImages(count: getCount)
                }
            }
        }else{
            DispatchQueue.main.async{
                refreshControl.endRefreshing()
            }
        }
    }
    
    func getChannels(completion: @escaping (Int) -> Void){
        var getCount = 0
        if !loadingChannels {
            loadingChannels = true
            let channelsAPIURLString: String
            if offset == 0 {
                channelsAPIURLString = channelsAPIURLStringTemplate0
                offset += overlap
            }else{
                channelsAPIURLString = "\(channelsAPIURLStringTemplate1)\(offset)"
                offset += offsetInc
            }
            
            if let streamsAPIURL = URL(string: channelsAPIURLString) {
                var request = URLRequest(url: streamsAPIURL )
                request.httpMethod = "GET"
                request.addValue(self.headerAcceptValue, forHTTPHeaderField: self.headerAcceptKey)
                request.addValue(self.headerClientIDValue, forHTTPHeaderField: self.headerClientIDKey)
                request.addValue("\(TwitchAPIManager.sharedInstance.authorizationValue)\(TwitchAPIManager.sharedInstance.oAuthToken!)", forHTTPHeaderField: TwitchAPIManager.sharedInstance.authorizationHeader)
                
                let session = URLSession.shared
                
                session.dataTask(with: request){ data, response, err in
                    if err == nil{
                        if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                                
                                if let dictionary = json as? [String: Any], let streams = dictionary["streams"] as? [[String: Any]]{
                                    if streams.count == 0 {
                                        self.got0 = true
                                    }
                                    
                                    for stream in streams{
                                        if let previews = stream["preview"] as? [String: String], let preview = previews["large"], let viewers = stream["viewers"] as? Int, let game = stream["game"] as? String, let channel = stream["channel"] as? [String: Any],let id = channel["_id"] as? Int, let name = channel["name"] as? String,let status = channel["status"] as? String{
                                            if !self.channelNames.contains(name){
                                                self.channels.append(Channel(id: id, viewers: viewers, status: status, game: game, name: name, previewURL: preview))
                                                self.channelNames.insert(name)
                                                getCount += 1
                                            }
                                        }
                                    }
                                }
                            } catch let error as NSError {
                                print("Failed to load: \(error.localizedDescription)")
                            }
                            
                        }
                    }else{
                        print("getStreams: \(err?.localizedDescription)")
                    }
                    completion(getCount)
                    self.loadingChannels = false
                    }.resume()
            }else{
                completion(getCount)
                self.loadingChannels = false
            }
        }else{
            completion(getCount)
        }
    }
    
    func downloadImages(count: Int){
        for i in channels.count - count..<channels.count{
            downloadImage(index: i)
        }
    }
    
    func downloadImage(index: Int){
        let previewURL = channels[index].previewURL
        
        if let url = URL(string: previewURL){
            let session = URLSession.shared
            session.dataTask(with: url){ data, response, err in
                if err == nil{
                    if let newData = data, let newImage = UIImage(data: newData){
                        self.channels[index].previewImage = newImage
                        let indexPath = IndexPath(row: index, section: 0)
                        if let indexPaths = self.tableView.indexPathsForVisibleRows, indexPaths.contains(indexPath) {
                            DispatchQueue.main.async{
                                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
                            }
                        }
                    }
                }else{
                    print("downloadImage: \(err?.localizedDescription)")
                }
                }.resume()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChat"{
            if let destinationViewController = segue.destination as? ChatViewController{
                destinationViewController.channel = channels[selectedIndex]
                destinationViewController.transitioningDelegate = self
                swipeInteractionController.wireToViewController(destinationViewController)
            }
        }
    }
}

extension FollowingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        selectedIndex = indexPath.row;
        //        self.performSegue(withIdentifier: "toChat", sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if index + 25 >= channels.count && !loadingChannels && !got0 {
            getChannels(){ getCount in
                if getCount > 0 {
                    var indexPaths = [IndexPath]()
                    for i in self.channels.count - getCount..<self.channels.count{
                        indexPaths.append(IndexPath(row: i, section: 0))
                    }
                    DispatchQueue.main.async{
                        self.tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.none)
                    }
                    self.downloadImages(count: getCount)
                }
            }
        }
    }
}

extension FollowingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelTableViewCell
        
        let index = indexPath.row
        
        cell.label1.attributedText = NSAttributedString(string: "\(channels[index].name)", attributes: strokeTextAttributes)
        cell.label2.attributedText = NSAttributedString(string: "\(channels[index].status)", attributes: strokeTextAttributes)
        cell.label3.attributedText = NSAttributedString(string: "\(channels[index].game) for \(NumberFormatController.commaFormattedNumber(number: channels[index].viewers)) viewers", attributes: strokeTextAttributes)
        
        if let image = channels[index].previewImage{
            cell.previewImage.image = image
        }
        
        return cell
    }
}

extension FollowingViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return slideLeftAnimationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return slideRightAnimationController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionController.interactionInProgress ? swipeInteractionController : nil
    }
}

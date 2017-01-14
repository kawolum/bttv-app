//
//  FollowingTableViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/6/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class FollowingTableViewController: UITableViewController {
    
    var channels = [Channel]()
    
    let streamsAPIURLString = "https://api.twitch.tv/kraken/streams/followed?limit=100&offset=0&stream_type=live"
    let headerAcceptKey = "Accept"
    let headerAcceptValue = "application/vnd.twitchtv.v5+json"
    let headerClientIDKey = "Client-ID"
    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    var selectedIndex = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let topLayoutGuideLength = self.topLayoutGuide.length;
        tableView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength, 0, 0, 0);
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        getStreams(){
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
            self.downloadImages()
        }
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        channels.removeAll()
        getStreams(){
            DispatchQueue.main.async{
                self.tableView.reloadData()
                refreshControl.endRefreshing()
            }
            self.downloadImages()
        }
    }
    
    func getStreams(completion: @escaping () -> Void){
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            
            if let streamsAPIURL = URL(string: self.streamsAPIURLString) {
                
                var request = URLRequest(url: streamsAPIURL )
                request.httpMethod = "GET"
                request.addValue(self.headerAcceptValue, forHTTPHeaderField: self.headerAcceptKey)
                request.addValue(self.headerClientIDValue, forHTTPHeaderField: self.headerClientIDKey)
                request.addValue(TwitchAPIManager.sharedInstance.authorizationValue+TwitchAPIManager.sharedInstance.oAuthToken!, forHTTPHeaderField: TwitchAPIManager.sharedInstance.authorizationHeader)
                
                let session = URLSession.shared
                
                session.dataTask(with: request){ data, response, err in
                    if err == nil{
                        if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                                if let dictionary = json as? [String: Any], let streams = dictionary["streams"] as? [[String: Any]]{
                                    for stream in streams{
                                        if let previews = stream["preview"] as? [String: String], let preview = previews["large"], let viewers = stream["viewers"] as? Int, let game = stream["game"] as? String, let channel = stream["channel"] as? [String: Any],let id = channel["_id"] as? Int, let name = channel["name"] as? String,let status = channel["status"] as? String{
                                            self.channels.append(Channel(id: id, viewers: viewers, status: status, game: game, name: name, previewURL: preview))
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
                    completion()
                }.resume()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row;
        self.performSegue(withIdentifier: "toChat", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelUITableViewCell
        
        let index = indexPath.row
        
        cell.label1.text = "\(channels[index].name)"
        cell.label2.text = "\(channels[index].status)"
        cell.label3.text = "streaming \(channels[index].game) for \(channels[index].viewers) viewers"
        
        if let image = channels[index].previewImage{
            cell.setPostedImage(image: image)
        }
        
        return cell
    }
    
    @IBAction func unwindToChannelsViewController(segue: UIStoryboardSegue) {
        print("Unwind to channels")
    }
    
    func downloadImages(){
        for i in 0..<channels.count{
            downloadImage(index: i)
        }
    }
    
    func downloadImage(index: Int){
        if let url = URL(string: channels[index].previewURL){
            let session = URLSession.shared
            session.dataTask(with: url){ data, response, err in
                if err == nil{
                    if let newData = data, let newImage = UIImage(data: newData){
                        self.channels[index].previewImage = newImage
                        DispatchQueue.main.async{
                            let indexPath = IndexPath(item: index, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .none)
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
            if let nextScene = segue.destination as? ChatViewController{
                nextScene.channel = channels[selectedIndex]
            }
        }
    }
}

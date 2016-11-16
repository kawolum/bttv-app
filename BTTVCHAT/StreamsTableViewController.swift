//
//  ChatsTableViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/16/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class StreamsTableViewController: UITableViewController {

    var streams = [Stream]()
    
    let streamsAPIURLString = "https://api.twitch.tv/kraken/streams?limit=25"
    let headerAcceptKey = "Accept"
    let headerAcceptValue = "application/vnd.twitchtv.v3+json"
    let headerClientIDKey = "Client-ID"
    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getStreams()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams.count
    }
    
    func getStreams(){
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            
            self.streams.append(Stream(viewers: 0, status: "same", game: "same", name: "kawolum822"))
            
            if let streamsAPIURL = URL(string: self.streamsAPIURLString) {
            
                var request = URLRequest(url: streamsAPIURL )
                request.httpMethod = "GET"
                request.addValue(self.headerAcceptValue, forHTTPHeaderField: self.headerAcceptKey)
                request.addValue(self.headerClientIDValue, forHTTPHeaderField: self.headerClientIDKey)
            
                let session = URLSession.shared
            
                session.dataTask(with: request){ data, response, err in
                    if err == nil{
                        if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                                if let dictionary = json as? [String: Any], let streams = dictionary["streams"] as? [[String: Any]]{
                                    for stream in streams{
                                        if let viewers = stream["viewers"] as? Int, let game = stream["game"] as? String, let channel = stream["channel"] as? [String: Any], let name = channel["name"] as? String,let status = channel["status"] as? String{
                                            self.streams.append(Stream(viewers: viewers, status: status, game: game, name: name))
                                        }
                                    }
                                    
                                    DispatchQueue.main.async{
                                        self.tableView.reloadData()
                                    }
                                    
                                }
                            } catch let error as NSError {
                                print("Failed to load: \(error.localizedDescription)")
                            }
                        
                        }
                    }else{
                        print("getStreams: \(err?.localizedDescription)")
                    }
                }.resume()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath)
        
        cell.textLabel?.text = "\(streams[(indexPath as NSIndexPath).row].name!) - \(streams[(indexPath as NSIndexPath).row].status!)"
        cell.detailTextLabel?.text = "\(streams[(indexPath as NSIndexPath).row].viewers!) - \(streams[(indexPath as NSIndexPath).row].game!)"
        
        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

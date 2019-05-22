//
//  SearchTableViewController.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/20/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import UIKit
import os.log

class SearchTableViewController: UITableViewController {
    
    var allStockSymbolList:Array<String> = []
    var filteredStockSymbolList:Array<String> = []
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        allStockSymbolList = getStockSymbolListFromJson()
        allStockSymbolList = allStockSymbolList.sorted()
        
        filteredStockSymbolList = allStockSymbolList
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Stock Symbols"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    // Get all stock symbols from local json file
    private func getStockSymbolListFromJson() -> Array<String> {
        var stockSymbolList: Array<String> = []
        
        if let path = Bundle.main.path(forResource: "stockSymbolList", ofType: "json") {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonObject = try? JSONSerialization.jsonObject(with: data)
                stockSymbolList = jsonObject as! Array<String>
            } catch {
                fatalError("Error while parsing stockSymbolList json")
            }
        }
        else {
            fatalError("Error: Can't find stockSymbolList")
        }
        
        if stockSymbolList.count == 0 {
            fatalError("Error while parsing stockSymbolList json: count == 0")
        }
        
        return stockSymbolList
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredStockSymbolList = allStockSymbolList.filter(
            { (stockSymbol : String) -> Bool in
                return stockSymbol.lowercased().starts(with: searchText.lowercased())
            })
        
        tableView.reloadData()
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredStockSymbolList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SearchTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SearchTableViewCell else {
            fatalError("The dequeued cell is not an instance of SearchTableViewCell.")
        }

        let stockSymbol = filteredStockSymbolList[indexPath.row]
        cell.symLabel.text = stockSymbol

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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let stockViewController = segue.destination as? StockViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedStockCell = sender as? SearchTableViewCell else {
            fatalError("Unexpected sender: \(sender ?? "unknown")")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedStockCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedStock = filteredStockSymbolList[indexPath.row]
        stockViewController.sym = selectedStock
        stockViewController.title = selectedStock
    }

}

extension SearchTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

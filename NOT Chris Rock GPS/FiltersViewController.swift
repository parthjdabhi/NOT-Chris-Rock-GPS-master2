//
//  FiltersViewController.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController

@objc protocol FiltersViewControllerDelegate {
    optional func filtersViewControllerDelegate( filtersViewController: FiltersViewController, didSet filters: Filters)
}

class FiltersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnBarCancel: UIBarButtonItem!
    
    @IBOutlet weak var vwSetting: UIView!
    @IBOutlet weak var swSettingMain: PDSwitch?
    @IBOutlet weak var swSettingSub: PDSwitch?
    
    var delegate: FiltersViewControllerDelegate?
    
    var distanceImg = ["expand_arrow", "check-circle-outline-blank","check-circle-outline-blank","check-circle-outline-blank","check-circle-outline-blank"]
    var distanceValues: [Float?] = [0.0, 0.3, 1, 5, 20]
    var categories = [[String:String]]()
    var sortValues = ["Best Match", "Distance", "Highest Rated"]
    var switchValues = [Int:Bool]()
    
    var filters = [String : AnyObject]()
    var filterObject = Filters()
    //Myfilters
    
    var isExpandedDistance = false
    var isExpandedSort = false
    var isSeeAll = false
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        categories = getCategories()
        
        swSettingMain?.titles = MainSetting
        swSettingSub?.titles = SubSetting
        
        swSettingMain?.setSelectedIndex(MainSetting.indexOf(Myfilters.SettingMain) ?? 0, animated: true)
        swSettingSub?.setSelectedIndex(SubSetting.indexOf(Myfilters.SettingSub) ?? 0, animated: true)
        
        if let revealVC = self.revealViewController() {
            btnBarCancel.title = "Menu"
            btnBarCancel.target = revealVC
            btnBarCancel.action = #selector(revealVC.revealToggle(_:))
        } else {
            btnBarCancel.target = self
            btnBarCancel.action = #selector(FiltersViewController.onCancel(_:))
        }
        
        //swSettingSub?.sendActionsForControlEvents(UIControlEvents)
    }
    
    override func viewWillDisappear(animated: Bool) {
        Myfilters.SettingMain = MainSetting[swSettingMain?.selectedIndex ?? 0]
        Myfilters.SettingSub = SubSetting[swSettingSub?.selectedIndex ?? 0]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSearch(sender: UIBarButtonItem) {
        filterObject.categories = [String]()
        for (k, v) in switchValues {
            if v {
                filterObject.categories.append(categories[k]["code"]!)
            }
        }
        filterObject.SettingMain = MainSetting[swSettingMain?.selectedIndex ?? 0]
        filterObject.SettingSub = SubSetting[swSettingSub?.selectedIndex ?? 0]
        self.delegate?.filtersViewControllerDelegate!(self, didSet: filterObject)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getDefaultFilters() {
        let defaulFilters = Filters()
        filterObject = defaulFilters
        switchValues = [Int:Bool]()
        tableView.reloadData()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

extension FiltersViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 6
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Distance"
        case 2:
            return "Sort By"
        case 3:
            return "Category"
        default:
            return nil
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return isExpandedDistance ? distanceValues.count: 1
        case 2:
            return isExpandedSort ? sortValues.count: 1
        case 3:
            return isSeeAll ? categories.count : 2
        case 4, 5:
            return 1
        default:
            return 0
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! FiltersSwitchTableViewCell
            cell.delegate = self
            cell.titleLabel.text = "Offering a Deal"
            cell.optionSwitch.on = filterObject.hasDeal
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("DropdownCell") as! FiltersDropdownTableViewCell
            cell.delegate = self
            
            let radius = filterObject.distance
            cell.titleLabel.text = radius > 0 ? ((radius! % 1 == 0 ? String(format: "%.0f", radius!) : String(format: "%.1f", radius!)) + " mile(s)") : "Auto"
            if isExpandedDistance {
                let distance = distanceValues[indexPath.row]
                if distance == 0.0 {
                    cell.titleLabel.text = "Auto"
                    if filterObject.distance == 0.0 {
                        cell.dropdownImage.image = UIImage(named: "check-circle-outline")
                    }
                } else {
                    cell.titleLabel.text = (distance! % 1 == 0 ? String(format: "%.0f", distance!) : String(format: "%.1f", distance!)) + " mile(s)"
                    cell.dropdownImage.image = (radius == distanceValues[indexPath.row]) ? UIImage(named: "check-circle-outline") : UIImage(named: "check-circle-outline-blank")
                }
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("DropdownCell") as! FiltersDropdownTableViewCell
            cell.delegate = self
            cell.titleLabel.text = sortValues[indexPath.row]
            cell.dropdownImage.image = UIImage(named: distanceImg[indexPath.row])
            if filterObject.sortBy != nil {
                let sortValue = filterObject.sortBy as! Int?
                if !isExpandedSort {
                    cell.titleLabel.text = "\(sortValues[sortValue!])"
                } else {
                    cell.dropdownImage.image = (sortValue == indexPath.row) ? UIImage(named: "check-circle-outline") : UIImage(named: "check-circle-outline-blank")
                }
            } else {
                if isExpandedSort {
                    cell.dropdownImage.image = UIImage(named: "check-circle-outline-blank")
                }
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! FiltersSwitchTableViewCell
            cell.delegate = self
//            if categories[indexPath.row]["name"] == filterObject.categories
            cell.titleLabel.text = categories[indexPath.row]["name"]
            switchValues[indexPath.row] = switchValues[indexPath.row] ??  false
            for k in filterObject.categories {
                if categories[indexPath.row]["code"] == k {
                    switchValues[indexPath.row] = true
                }
            }
            cell.optionSwitch.on = switchValues[indexPath.row]!
            return cell
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier("SeeAllCell") as! FiltersSeeAllTableViewCell
            cell.delegate = self
            cell.titleLabel.text = isSeeAll ? "Show less" : "See all"
            return cell
        case 5:
            let cell = tableView.dequeueReusableCellWithIdentifier("SeeAllCell") as! FiltersSeeAllTableViewCell
            cell.delegate = self
            cell.titleLabel.text = "Reset"
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
        
    }
}
extension FiltersViewController: FiltersSwitchDelegate, FiltersDropdownDelegate, FiltersSeeAllDelegate {
    func filtersSwitchDelegate(filtersSwitchTableViewCell: FiltersSwitchTableViewCell, didSet isSelected: Bool) {
        let indexPath = tableView.indexPathForCell(filtersSwitchTableViewCell)
        if indexPath != nil {
            switch indexPath!.section {
            case 0:
                filterObject.hasDeal = isSelected
            case 3:
                switchValues[(indexPath?.row)!] = isSelected
            default:
                break
            }
         }
    }
    
    func filtersDropdownDelegate(filtersDropdownTableViewCell: FiltersDropdownTableViewCell, didSet dropdownImg: UIImage) {
        let indexPath = tableView.indexPathForCell(filtersDropdownTableViewCell)
        if indexPath != nil {
            switch indexPath!.section {
            case 1:
                switch dropdownImg {
                case UIImage(named: "expand_arrow")!:
                    isExpandedDistance = isExpandedDistance ? false : true
                case UIImage(named: "check-circle-outline-blank")!:
                    filterObject.distance = distanceValues[indexPath!.row]
                    isExpandedDistance = false
                case UIImage(named: "check-circle-outline")!:
                    isExpandedDistance = false
                default:
                    break
                }
                
                tableView.reloadSections(NSIndexSet(index: (indexPath?.section)!), withRowAnimation: .Automatic)
            case 2:
                switch dropdownImg {
                case UIImage(named: "expand_arrow")!:
                    isExpandedSort = isExpandedSort ? false : true
                case UIImage(named: "check-circle-outline-blank")!:
                    filterObject.sortBy = indexPath!.row
                    isExpandedSort = false
                case UIImage(named: "check-circle-outline")!:
                    isExpandedSort = false
                default:
                    break
                }
                
                tableView.reloadSections(NSIndexSet(index: (indexPath?.section)!), withRowAnimation: .Automatic)
            default:
                break
            }
            
        }
    }
    func filtersSeeAllDelegate(filtersSeeAllTableViewCell: FiltersSeeAllTableViewCell, didSet title: String) {
        let indexPath = tableView.indexPathForCell(filtersSeeAllTableViewCell)
        if indexPath != nil {
            switch indexPath!.section {
            case 4:
                isSeeAll = !isSeeAll
                tableView.reloadSections(NSIndexSet(index: (3)), withRowAnimation: .Automatic)
                tableView.reloadSections(NSIndexSet(index: (indexPath?.section)!), withRowAnimation: .Automatic)
            case 5:
                getDefaultFilters()
            default:
                break
            }
        }
    }
}

extension FiltersViewController {
    func getCategories() -> [[String: String]]{
        return [["name" : "Afghan", "code": "afghani"],
                ["name" : "African", "code": "african"],
                ["name" : "American, New", "code": "newamerican"],
                ["name" : "American, Traditional", "code": "tradamerican"],
                ["name" : "Arabian", "code": "arabian"],
                ["name" : "Argentine", "code": "argentine"],
                ["name" : "Armenian", "code": "armenian"],
                ["name" : "Asian Fusion", "code": "asianfusion"],
                ["name" : "Asturian", "code": "asturian"],
                ["name" : "Australian", "code": "australian"],
                ["name" : "Austrian", "code": "austrian"],
                ["name" : "Baguettes", "code": "baguettes"],
                ["name" : "Bangladeshi", "code": "bangladeshi"],
                ["name" : "Barbeque", "code": "bbq"],
                ["name" : "Basque", "code": "basque"],
                ["name" : "Bavarian", "code": "bavarian"],
                ["name" : "Beer Garden", "code": "beergarden"],
                ["name" : "Beer Hall", "code": "beerhall"],
                ["name" : "Beisl", "code": "beisl"],
                ["name" : "Belgian", "code": "belgian"],
                ["name" : "Bistros", "code": "bistros"],
                ["name" : "Black Sea", "code": "blacksea"],
                ["name" : "Brasseries", "code": "brasseries"],
                ["name" : "Brazilian", "code": "brazilian"],
                ["name" : "Breakfast & Brunch", "code": "breakfast_brunch"],
                ["name" : "British", "code": "british"],
                ["name" : "Buffets", "code": "buffets"],
                ["name" : "Bulgarian", "code": "bulgarian"],
                ["name" : "Burgers", "code": "burgers"],
                ["name" : "Burmese", "code": "burmese"],
                ["name" : "Cafes", "code": "cafes"],
                ["name" : "Cafeteria", "code": "cafeteria"],
                ["name" : "Cajun/Creole", "code": "cajun"],
                ["name" : "Cambodian", "code": "cambodian"],
                ["name" : "Canadian", "code": "New)"],
                ["name" : "Canteen", "code": "canteen"],
                ["name" : "Caribbean", "code": "caribbean"],
                ["name" : "Catalan", "code": "catalan"],
                ["name" : "Chech", "code": "chech"],
                ["name" : "Cheesesteaks", "code": "cheesesteaks"],
                ["name" : "Chicken Shop", "code": "chickenshop"],
                ["name" : "Chicken Wings", "code": "chicken_wings"],
                ["name" : "Chilean", "code": "chilean"],
                ["name" : "Chinese", "code": "chinese"],
                ["name" : "Comfort Food", "code": "comfortfood"],
                ["name" : "Corsican", "code": "corsican"],
                ["name" : "Creperies", "code": "creperies"],
                ["name" : "Cuban", "code": "cuban"],
                ["name" : "Curry Sausage", "code": "currysausage"],
                ["name" : "Cypriot", "code": "cypriot"],
                ["name" : "Czech", "code": "czech"],
                ["name" : "Czech/Slovakian", "code": "czechslovakian"],
                ["name" : "Danish", "code": "danish"],
                ["name" : "Delis", "code": "delis"],
                ["name" : "Diners", "code": "diners"],
                ["name" : "Dumplings", "code": "dumplings"],
                ["name" : "Eastern European", "code": "eastern_european"],
                ["name" : "Ethiopian", "code": "ethiopian"],
                ["name" : "Fast Food", "code": "hotdogs"],
                ["name" : "Filipino", "code": "filipino"],
                ["name" : "Fish & Chips", "code": "fishnchips"],
                ["name" : "Fondue", "code": "fondue"],
                ["name" : "Food Court", "code": "food_court"],
                ["name" : "Food Stands", "code": "foodstands"],
                ["name" : "French", "code": "french"],
                ["name" : "French Southwest", "code": "sud_ouest"],
                ["name" : "Galician", "code": "galician"],
                ["name" : "Gastropubs", "code": "gastropubs"],
                ["name" : "Georgian", "code": "georgian"],
                ["name" : "German", "code": "german"],
                ["name" : "Giblets", "code": "giblets"],
                ["name" : "Gluten-Free", "code": "gluten_free"],
                ["name" : "Greek", "code": "greek"],
                ["name" : "Halal", "code": "halal"],
                ["name" : "Hawaiian", "code": "hawaiian"],
                ["name" : "Heuriger", "code": "heuriger"],
                ["name" : "Himalayan/Nepalese", "code": "himalayan"],
                ["name" : "Hong Kong Style Cafe", "code": "hkcafe"],
                ["name" : "Hot Dogs", "code": "hotdog"],
                ["name" : "Hot Pot", "code": "hotpot"],
                ["name" : "Hungarian", "code": "hungarian"],
                ["name" : "Iberian", "code": "iberian"],
                ["name" : "Indian", "code": "indpak"],
                ["name" : "Indonesian", "code": "indonesian"],
                ["name" : "International", "code": "international"],
                ["name" : "Irish", "code": "irish"],
                ["name" : "Island Pub", "code": "island_pub"],
                ["name" : "Israeli", "code": "israeli"],
                ["name" : "Italian", "code": "italian"],
                ["name" : "Japanese", "code": "japanese"],
                ["name" : "Jewish", "code": "jewish"],
                ["name" : "Kebab", "code": "kebab"],
                ["name" : "Korean", "code": "korean"],
                ["name" : "Kosher", "code": "kosher"],
                ["name" : "Kurdish", "code": "kurdish"],
                ["name" : "Laos", "code": "laos"],
                ["name" : "Laotian", "code": "laotian"],
                ["name" : "Latin American", "code": "latin"],
                ["name" : "Live/Raw Food", "code": "raw_food"],
                ["name" : "Lyonnais", "code": "lyonnais"],
                ["name" : "Malaysian", "code": "malaysian"],
                ["name" : "Meatballs", "code": "meatballs"],
                ["name" : "Mediterranean", "code": "mediterranean"],
                ["name" : "Mexican", "code": "mexican"],
                ["name" : "Middle Eastern", "code": "mideastern"],
                ["name" : "Milk Bars", "code": "milkbars"],
                ["name" : "Modern Australian", "code": "modern_australian"],
                ["name" : "Modern European", "code": "modern_european"],
                ["name" : "Mongolian", "code": "mongolian"],
                ["name" : "Moroccan", "code": "moroccan"],
                ["name" : "New Zealand", "code": "newzealand"],
                ["name" : "Night Food", "code": "nightfood"],
                ["name" : "Norcinerie", "code": "norcinerie"],
                ["name" : "Open Sandwiches", "code": "opensandwiches"],
                ["name" : "Oriental", "code": "oriental"],
                ["name" : "Pakistani", "code": "pakistani"],
                ["name" : "Parent Cafes", "code": "eltern_cafes"],
                ["name" : "Parma", "code": "parma"],
                ["name" : "Persian/Iranian", "code": "persian"],
                ["name" : "Peruvian", "code": "peruvian"],
                ["name" : "Pita", "code": "pita"],
                ["name" : "Pizza", "code": "pizza"],
                ["name" : "Polish", "code": "polish"],
                ["name" : "Portuguese", "code": "portuguese"],
                ["name" : "Potatoes", "code": "potatoes"],
                ["name" : "Poutineries", "code": "poutineries"],
                ["name" : "Pub Food", "code": "pubfood"],
                ["name" : "Rice", "code": "riceshop"],
                ["name" : "Romanian", "code": "romanian"],
                ["name" : "Rotisserie Chicken", "code": "rotisserie_chicken"],
                ["name" : "Rumanian", "code": "rumanian"],
                ["name" : "Russian", "code": "russian"],
                ["name" : "Salad", "code": "salad"],
                ["name" : "Sandwiches", "code": "sandwiches"],
                ["name" : "Scandinavian", "code": "scandinavian"],
                ["name" : "Scottish", "code": "scottish"],
                ["name" : "Seafood", "code": "seafood"],
                ["name" : "Serbo Croatian", "code": "serbocroatian"],
                ["name" : "Signature Cuisine", "code": "signature_cuisine"],
                ["name" : "Singaporean", "code": "singaporean"],
                ["name" : "Slovakian", "code": "slovakian"],
                ["name" : "Soul Food", "code": "soulfood"],
                ["name" : "Soup", "code": "soup"],
                ["name" : "Southern", "code": "southern"],
                ["name" : "Spanish", "code": "spanish"],
                ["name" : "Steakhouses", "code": "steak"],
                ["name" : "Sushi Bars", "code": "sushi"],
                ["name" : "Swabian", "code": "swabian"],
                ["name" : "Swedish", "code": "swedish"],
                ["name" : "Swiss Food", "code": "swissfood"],
                ["name" : "Tabernas", "code": "tabernas"],
                ["name" : "Taiwanese", "code": "taiwanese"],
                ["name" : "Tapas Bars", "code": "tapas"],
                ["name" : "Tapas/Small Plates", "code": "tapasmallplates"],
                ["name" : "Tex-Mex", "code": "tex-mex"],
                ["name" : "Thai", "code": "thai"],
                ["name" : "Traditional Norwegian", "code": "norwegian"],
                ["name" : "Traditional Swedish", "code": "traditional_swedish"],
                ["name" : "Trattorie", "code": "trattorie"],
                ["name" : "Turkish", "code": "turkish"],
                ["name" : "Ukrainian", "code": "ukrainian"],
                ["name" : "Uzbek", "code": "uzbek"],
                ["name" : "Vegan", "code": "vegan"],
                ["name" : "Vegetarian", "code": "vegetarian"],
                ["name" : "Venison", "code": "venison"],
                ["name" : "Vietnamese", "code": "vietnamese"],
                ["name" : "Wok", "code": "wok"],
                ["name" : "Wraps", "code": "wraps"],
                ["name" : "Yugoslav", "code": "yugoslav"]]
    }
}

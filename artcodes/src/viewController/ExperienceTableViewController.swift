import Foundation
import artcodesScanner

class ExperienceTableViewController: ArtcodeViewController, UITableViewDataSource, UITableViewDelegate
{
    var groups: [String: [String]] = [:]
   	var experiences: [String: Experience] = [:]
   	var keys: [String] = []
    var sorted = false
   	var ordering: [String]
    {
        return []
    }
    
    let progressView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
	@IBOutlet weak var tableView: UITableView!
	
	init()
	{
		super.init(nibName:"ExperienceTableViewController", bundle:nil)
	}
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
    func addExperienceURIs(experienceURIs: [String], forGroup: String)
    {
        groups[forGroup] = experienceURIs
        
        // Update keys
        keys = []
        for key in ordering
        {
            if groups.indexForKey(key) != nil
            {
                keys.append(key)
            }
        }
        
        for key in groups.keys
        {
            if !keys.contains(key)
            {
                keys.append(key)
            }
        }
        
        for experienceURI in experienceURIs
        {
            NSLog("Adding \(experienceURI) in \(forGroup)")
            if experiences.indexForKey(experienceURI) == nil
            {
                self.server.loadExperience(experienceURI) { (experience) -> Void in
                    NSLog("Loaded \(experienceURI)")
                    self.experiences[experienceURI] = experience
                    self.tableView.reloadData()
                }
            }
        }
    }
    
	override func viewDidLoad()
	{
		super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 56.0;
        
		let nibName = UINib(nibName: "ExperienceViewCell", bundle:nil)
		tableView.registerNib(nibName, forCellReuseIdentifier: "ExperienceViewCell")
        
        progressView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        progressView.center = view.center
        progressView.hidesWhenStopped = true
        view.addSubview(progressView)
        progressView.startAnimating()
    }
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let experienceURIs = groups[keys[section]]
        {
            var count = 0
            for experienceURI in experienceURIs
            {
                if experiences.indexForKey(experienceURI) != nil
                {
                    count++
                }
            }
            return count
        }
        return 0
    }
    
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell :ExperienceViewCell = tableView.dequeueReusableCellWithIdentifier("ExperienceViewCell") as! ExperienceViewCell
		cell.experience = experienceAt(indexPath)
		return cell;
	}
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return NSLocalizedString(keys[section], tableName: nil, bundle: NSBundle.mainBundle(), value: keys[section], comment: "")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return keys.count
    }
    
    func experienceAt(indexPath: NSIndexPath) -> Experience?
    {
        if let items = groups[keys[indexPath.section]]
        {
            var experienceList : [Experience] = []
            for item in items
            {
                if let experience = experiences[item]
                {
                    experienceList.append(experience)
                }
            }
            
            if sorted
            {
                experienceList.sortInPlace({ $0.name?.lowercaseString < $1.name?.lowercaseString })
            }
            
            return experienceList[indexPath.item]
        }
        return nil
    }
}
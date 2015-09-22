import Foundation


public enum Visibility
{
	case personal
	case secret
	case published
}

public class Experience
{
	public var actions = [Action]()
	public var availabilities = [Availability]()
	// TODO public var processors = [ImageProcessor]()
	public var id: String
	public var name: String?
	public var icon: String?
	public var image: String?
	public var description: String?
	public var author: String?
	public var originalID: String?
	public var visibility = Visibility.secret
	public var checksumModulo = 3
	public var embeddedChecksum = false
	public var editable = false
	public var detector: String?
	
    public var markerSettings: MarkerSettings
    {
        return MarkerSettings()
    }
    
	public init(experienceID: String)
	{
		id = experienceID
	}
	
	public func update()
	{
	
	}
}
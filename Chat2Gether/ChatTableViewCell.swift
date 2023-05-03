//
//  ChatTableViewCell.swift
//  Chat2Gether
//
//  Created by Sinem  on 31.01.2023.
//

import UIKit

class ChatTableViewCell: UITableViewCell
{
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }

}

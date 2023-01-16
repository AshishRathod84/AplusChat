//
//  ChatVC.swift
//  ConvertedAGS
//
//  Created by Auxano on 12/10/22.
//

import UIKit
import AVKit
import MobileCoreServices

public class ChatVC: UIViewController {

    @IBOutlet weak var viewMainChat: UIView!
    @IBOutlet weak var viewBackUserName: UIView!
    @IBOutlet weak var viewBack: UIView!
    @IBOutlet weak var imgBack: UIImageView!
    @IBOutlet weak var imgProfilePic: UIImageView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var viewUserInfo: UIView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var btnUserInfo: UIButton!
    @IBOutlet weak var btnOption: UIButton!
    @IBOutlet weak var viewTypeMsg: UIView!
    @IBOutlet weak var txtTypeMsg: UITextField!
    @IBOutlet weak var btnAttach: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var viewChat: UIView!
    @IBOutlet weak var imgChatBackground: UIImageView!
    @IBOutlet weak var constMainChatViewBottom: NSLayoutConstraint!
    @IBOutlet weak var tblUserChat: UITableView!
    @IBOutlet weak var lblOnline: UILabel!
    @IBOutlet weak var constViewTypeMsgHeight: NSLayoutConstraint!

    var strDisName : String?
    var strProfileImg : String? = ""
    var isNetworkAvailable : Bool = false
    var isKeyboardActive : Bool = false
    var imagePicker = UIImagePickerController()
    var arrImageExtension : [String] = ["jpg", "png", "jpeg", "gif", "svg"]
    var arrDocExtension : [String] = ["doc", "docx", "xls", "xlsx", "pdf", "rtf", "txt", ""]
    var arrAudioExtension : [String] = ["mp3", "aac", "wav", "ogg", "m4a"]
    var arrVideoExtension : [String] = ["mp4", "avi", "mov", "3gp", "3gpp", "mpg", "mpeg", "webm", "flv", "m4v", "wmv", "asx", "asf"]
    var isCameraClick : Bool = false
    
    var groupId : String = "abc"    //  roomId
    
    var arrGetPreviousChat : [GetPreviousChat]? = []
    var arrDtForSection : [String]? = []
    var arrSectionMsg : [[GetPreviousChat]]? = [[]]
    var isReceiveMsgOn : Bool = false
    var recentChatUser : GetUserList?
    var isGroup : Bool = false
    var isClear : Bool = false
    
    var imgFileName : String = ""
    var isDocumentPickerOpen : Bool = false
    var isTyping : Bool = false
    var timer = Timer()
    var timeSeconds = 1
    var onlineUser : String = ""
    
    public init() {
        super.init(nibName: "UserChatVC", bundle: Bundle(for: ChatVC.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented FirstViewController")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.viewTypeMsg.backgroundColor = .clear
        btnAttach.backgroundColor = .white
        btnAttach.layer.cornerRadius = btnAttach.frame.height / 2
        btnSend.backgroundColor = .white
        btnSend.layer.cornerRadius = btnSend.frame.width / 2
        
        groupId = recentChatUser?.groupId ?? ""
        self.setData()
        
        if Network.reachability.isReachable {
            isNetworkAvailable = true
        }
        
        if #available(iOS 15.0, *) {
            tblUserChat.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
    
        let bundle = Bundle(for: ChatVC.self)
        NotificationCenter.default.addObserver(self, selector: #selector(checkConnection), name: .flagsChanged, object: nil)
        
        tblUserChat.register(UINib(nibName: "OwnChatBubbleCell", bundle: bundle), forCellReuseIdentifier: "OwnChatBubbleCell")
        tblUserChat.register(UINib(nibName: "OwnImgChatBubbleCell", bundle: bundle), forCellReuseIdentifier: "OwnImgChatBubbleCell")
        tblUserChat.register(UINib(nibName: "OwnFileBubbleCell", bundle: bundle), forCellReuseIdentifier: "OwnFileBubbleCell")
        tblUserChat.register(UINib(nibName: "OwnAudioBubbleCell", bundle: bundle), forCellReuseIdentifier: "OwnAudioBubbleCell")
        
        tblUserChat.register(UINib(nibName: "OtherChatBubbleCell", bundle: bundle), forCellReuseIdentifier: "OtherChatBubbleCell")
        tblUserChat.register(UINib(nibName: "OtherImgChatBubbleCell", bundle: bundle), forCellReuseIdentifier: "OtherImgChatBubbleCell")
        tblUserChat.register(UINib(nibName: "OtherFileBubbleCell", bundle: bundle), forCellReuseIdentifier: "OtherFileBubbleCell")
        tblUserChat.register(UINib(nibName: "OtherAudioBubbleCell", bundle: bundle), forCellReuseIdentifier: "OtherAudioBubbleCell")
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        txtTypeMsg.delegate = self
        imgProfilePic.layer.cornerRadius = imgProfilePic.frame.width / 2
        
        if !isDocumentPickerOpen {
            SocketChatManager.sharedInstance.joinGroup(param: groupId)
            //SocketChatManager.sharedInstance.joinGroup(param: ["groupId" : groupId, "_id" : myUserId, "name" : "Pranay"])
            SocketChatManager.sharedInstance.userChatVC = {
                return self
            }
            SocketChatManager.sharedInstance.reqGroupDetail(param: ["userId": myUserId, "secretKey": secretKey, "groupId": groupId])
            SocketChatManager.sharedInstance.reqPreviousChatMsg(param: ["groupId" : groupId, "_id" : myUserId])
        } else {
            self.isDocumentPickerOpen = false
        }
        
        if #available(iOS 14.0, *) {
            self.loadPopup()
        } else {
            // Fallback on earlier versions
        }
        //Delegate for receive other user message.
        SocketChatManager.sharedInstance.socketDelegate = self
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if !isDocumentPickerOpen {
            SocketChatManager.sharedInstance.leaveChat(roomid: groupId)
            SocketChatManager.sharedInstance.socket?.off("typing-res")
        }
    }
    
    func setData() {
        
        btnOption.tintColor = UIColor.black
        self.btnOption.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        registerKeyboardNotifications()
        lblUserName.text = strDisName
        onlineUser = isGroup ? "" : "Online"
        
        if recentChatUser?.isGroup ?? false {
            self.imgProfilePic.image = UIImage(named: "group-placeholder")
            isGroup = true
            strDisName = (recentChatUser?.name)!
            strProfileImg = recentChatUser?.groupImage ?? ""
            lblOnline.text = ""
        } else {
            //btnSend.isEnabled = false
            //btnAttach.isEnabled = false
            //txtTypeMsg.isEnabled = false
            viewTypeMsg.isHidden = true
            constViewTypeMsgHeight.constant = 0
            
            if SocketChatManager.sharedInstance.userRole?.sendMessage ?? 0 == 1 {
                viewTypeMsg.isHidden = false
                constViewTypeMsgHeight.constant = 55
            }
            
            isGroup = false
            self.imgProfilePic.image = UIImage(named: "placeholder-profile-img")
            for i in 0 ..< (recentChatUser?.users?.count ?? 0) {
                if (recentChatUser?.users?[i].userId)! != myUserId {
                    strDisName = (recentChatUser?.users?[i].name)!
                    strProfileImg = recentChatUser?.users?[i].profilePicture ?? ""
                }
            }
            lblOnline.text = "Online"
        }
        
        if strProfileImg != "" {
            var imageURL: URL?
            imageURL = URL(string: strProfileImg!)!
            // retrieves image if already available in cache
            if let imageFromCache = imageCache.object(forKey: imageURL as AnyObject) as? UIImage {
                self.imgProfilePic.image = imageFromCache
                return
            }
            NetworkManager.sharedInstance.getData(from: URL(string: strProfileImg!)!) { data, response, err in
                if err == nil {
                    DispatchQueue.main.async {
                        //self.imgProfilePic.image = UIImage(data: data!)
                        if let imageToCache = UIImage(data: data!) {
                            self.imgProfilePic.image = imageToCache
                            imageCache.setObject(imageToCache, forKey: imageURL as AnyObject)
                        } else {
                            self.imgProfilePic.image = self.isGroup ? UIImage(named: "group-placeholder") : UIImage(named: "placeholder-profile-img")
                        }
                    }
                }
            }
        }
    }
    
    
    func getGroupDetail(groupDetail : GetUserList) {
        recentChatUser = groupDetail
        self.setData()
    }
    
    func getPreviousChat(chat : [GetPreviousChat]) {
        self.arrGetPreviousChat = chat
        //Call func for get section.
        self.arrDtForSection?.removeAll()
        self.arrSectionMsg?.removeAll()
        self.getDateforSection()
        self.tblUserChat.reloadData()
        if (arrDtForSection!.count > 0) && (arrSectionMsg!.count > 0) {
            tblUserChat.scrollToRow(at: IndexPath(row: (self.arrSectionMsg![arrSectionMsg!.count - 1].count - 1), section: (arrSectionMsg!.count - 1)), at: .bottom, animated: false)
        }
        SocketChatManager.sharedInstance.typingRes()
        SocketChatManager.sharedInstance.unreadCountZero(param: ["userId" : myUserId, "secretKey" : secretKey, "groupId" : groupId])
    }
    
    func getTypingResponse(typingResponse : TypingResponse) {
        if (typingResponse.groupId == groupId)  {
            if typingResponse.isTyping == "true" {
                if recentChatUser?.isGroup ?? false {
                    onlineUser = "\(typingResponse.name ?? "") typing"
                } else {
                    onlineUser = "typing..."
                }
                lblOnline.text = onlineUser
            } else if typingResponse.isTyping == "false" {
                if recentChatUser?.isGroup ?? false {
                    onlineUser = ""
                } else {
                    onlineUser = "Online"
                }
                lblOnline.text = onlineUser
            }
        }
    }
    
    func getDateforSection() {
        for i in 0 ..< arrGetPreviousChat!.count {
            let msgDate : String = Utility.convertTimestamptoDateString(timestamp: (self.arrGetPreviousChat?[i].sentAt?.seconds)!)
            if (arrDtForSection?.contains(msgDate))! {
                for j in 0 ..< arrDtForSection!.count {
                    if arrDtForSection![j] == msgDate {
                        arrSectionMsg?[j].append((self.arrGetPreviousChat?[i])!)
                    }
                }
            } else {
                arrDtForSection?.append(msgDate)
                var tempMsg : [GetPreviousChat] = []
                tempMsg.append((self.arrGetPreviousChat?[i])!)
                arrSectionMsg?.append(tempMsg)
            }
        }
    }
    
    @objc func checkConnection(_ notification: Notification) {
        updateUserInterface()
    }
    
    func updateUserInterface() {
        switch Network.reachability.isReachable {
        case true:
            if !self.isNetworkAvailable {
                self.isNetworkAvailable = true
                let toastMsg = ToastUtility.Builder(message: "Internet available.", controller: self, keyboardActive: isKeyboardActive)
                toastMsg.setColor(background: .green, text: .black)
                toastMsg.show()
            }
            print("Network connection available.")
            break
        case false:
            if isNetworkAvailable {
                self.isNetworkAvailable = false
                let toastMsg = ToastUtility.Builder(message: "No Internet connection.", controller: self, keyboardActive: isKeyboardActive)
                toastMsg.setColor(background: .red, text: .black)
                toastMsg.show()
            }
            SocketChatManager.sharedInstance.establishConnection()
            break
        }
    }
    
    @IBAction func btnBackTap(_ sender: UIButton) {
        //SocketChatManager.sharedInstance.leaveChat(roomid: groupId)
        self.navigationController?.popToRootViewController(animated: true)
        SocketChatManager.sharedInstance.socket?.off("typing-res")
    }
    
    @IBAction func btnUserInfoTap(_ sender: UIButton) {
        self.moveToContactInfo()
    }
    
    @available(iOS 14.0, *)
    func loadPopup() {
        let contectInfo = UIAction(title: "\(isGroup ? "Group" : "Contact") Info", image: UIImage(systemName: "")){ action in
            //person.fill - image
            self.moveToContactInfo()
        }
        let deleteChat = UIAction(title: "Delete \(isGroup ? "Group" : "Chat")", image: UIImage(systemName: "")){ action in
            //trash.fill - image
            print("Delete chat")
            self.deleteChat()
        }
        let clearChat = UIAction(title: "Clear Chat", image: UIImage(systemName: "")){ action in
            //ellipses.bubble.fill - image
            self.clearChat()
        }
        
        var menu = UIMenu()
        if isGroup {
            menu = UIMenu(title: "", options: .displayInline, children: [contectInfo , deleteChat, clearChat])
        } else {
            menu = UIMenu(title: "", options: .displayInline, children: [contectInfo , deleteChat])
            if SocketChatManager.sharedInstance.userRole?.deleteMessage ?? 0 == 1 {
                menu = UIMenu(title: "", options: .displayInline, children: [contectInfo , deleteChat , clearChat])
            }
        }
        btnOption.menu = menu
    }
    
    func moveToContactInfo() {
//        let sb = UIStoryboard(name: "Main", bundle: nil)
//        let vc = sb.instantiateViewController(withIdentifier: "ContectInfoVC") as! ContectInfoVC
//        //vc.myUserId = self.myUserId
//        vc.groupId = self.groupId
//        vc.recentChatUser = self.recentChatUser
//        vc.userChatVC = { return self }
//        self.navigationController?.pushViewController(vc, animated: true)
        
        let vc = ContactInfoVC()
        vc.groupId = self.groupId
        vc.recentChatUser = self.recentChatUser
        vc.userChatVC = { return self }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func clearChat() {
        let alertController = UIAlertController(title: "Are you sure you want to clear chat ?", message: "", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            //Delete chat
            self.isClear = true
            SocketChatManager.sharedInstance.clearChat(param: ["userId" : myUserId, "groupId" : self.groupId])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { action in
        }
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteChat() {
        let alertController = UIAlertController(title: "Are you sure you want to delete \(isGroup ? "group" : "chat") ?", message: "", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            //Delete chat
            self.isClear = false
            if !self.isGroup {
                SocketChatManager.sharedInstance.deleteChat(param: ["userId" : myUserId, "groupId" : self.groupId], from: true)
            } else {
                SocketChatManager.sharedInstance.deleteGroup(param: ["userId" : myUserId, "groupId" : self.groupId], from: true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { action in
        }
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func responseBack(_ isUpdate : Bool) {
        if isUpdate {
            if isClear {
                self.arrGetPreviousChat?.removeAll()
                self.arrDtForSection?.removeAll()
                self.arrSectionMsg?.removeAll()
                self.tblUserChat.reloadData()
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func memberRemoveRes(_ isSuccess : Bool, updatedRecentChatUser : GetUserList) {
        if isSuccess {
            self.recentChatUser = updatedRecentChatUser
        }
    }
    
    @available(iOS 14.0, *)
    @IBAction func btnOptionTap(_ sender: UIButton) {
        btnOption.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func btnAttachTap(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let alert = UIAlertController(title: "", message: "Please select an option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { alert in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "From library", style: .default, handler: { alert in
            self.fromLibrary()
        }))
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { alert in
            if #available(iOS 14.0, *) {
                self.selectFiles()
            } else {
                // Fallback on earlier versions
            }
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { alert in
        }))
        self.present(alert, animated: true) {
        }
    }
    
    @IBAction func btnSendTap(_ sender: UIButton) {
        if txtTypeMsg.text! != "" {
            let param : [String : Any] = ["message": txtTypeMsg.text!, "isRead" : false, "type" : "text", "viewBy" : (recentChatUser?.members)!, "readBy" : myUserId, "sentAt" : "", "sentBy" : myUserId, "timeMilliSeconds" : ""]
            let param1 : [String : Any] = ["messageObj" : param, "groupId" : (recentChatUser?.groupId)!, "secretKey" : secretKey, "userId": myUserId, "userName": myUserName]
            //SocketChatManager.sharedInstance.sendMsg(message: param1)
            
            if self.sendMessage(param: param1) {
                let timestamp : Int = Int(NSDate().timeIntervalSince1970)
                let sentAt : [String : Any] = ["seconds" : timestamp]
                let msg : [String : Any] = ["sentBy" : myUserId,
                                            "type" : "text",
                                            "sentAt" : sentAt,
                                            "message" : txtTypeMsg.text!]
                
                if self.loadChatMsgToArray(msg: msg, timestamp: timestamp) {
                    txtTypeMsg.text = ""
                    tblUserChat.reloadData()
                    tblUserChat.scrollToRow(at: IndexPath(row: (self.arrSectionMsg![arrSectionMsg!.count - 1].count - 1), section: (arrSectionMsg!.count - 1)), at: .bottom, animated: true)
                    //self.view.endEditing(true)
                }
            }
        }
    }
    
    func sendMessage(param : [String : Any]) -> Bool {
        if Network.reachability.isReachable {
            if SocketChatManager.sharedInstance.socket?.status == .connected {
                SocketChatManager.sharedInstance.sendMsg(message: param)
                return true
            } else {
                let toastMsg = ToastUtility.Builder(message: "Server not connected.", controller: self, keyboardActive: isKeyboardActive)
                toastMsg.setColor(background: .red, text: .black)
                toastMsg.show()
                return false
            }
        } else {
            let toastMsg = ToastUtility.Builder(message: "No Internet connection.", controller: self, keyboardActive: isKeyboardActive)
            toastMsg.setColor(background: .red, text: .black)
            toastMsg.show()
            return false
        }   //  */
    }
}

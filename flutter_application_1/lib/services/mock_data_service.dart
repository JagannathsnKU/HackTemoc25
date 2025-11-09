import '../models/conversation.dart';

class MockDataService {
  static List<Conversation> getMockConversations() {
    final now = DateTime.now();
    
    return [
      // Person 1: Sent 5 messages, NO REPLY from user - Should have LOW health score
      // Person 1: High activity - Should have HIGH health score
      Conversation(
        id: '1',
        contactName: 'Alex Chen',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        hasUnread: true,
        messages: [
          ChatMessage(id: '1', text: 'Hey! We should collab on that DeFi protocol', isUser: false, timestamp: now.subtract(const Duration(days: 15))),
          ChatMessage(id: '2', text: 'Yeah definitely! Send me the details', isUser: true, timestamp: now.subtract(const Duration(days: 15, hours: -2))),
          ChatMessage(id: '3', text: 'Here\'s the GitHub repo link', isUser: false, timestamp: now.subtract(const Duration(days: 14))),
          ChatMessage(id: '4', text: 'Did you see the new NFT drop?', isUser: false, timestamp: now.subtract(const Duration(days: 10))),
          ChatMessage(id: '5', text: 'The Solana ecosystem is going crazy rn', isUser: false, timestamp: now.subtract(const Duration(days: 9))),
          ChatMessage(id: '6', text: 'Bro we should catch up about that project', isUser: false, timestamp: now.subtract(const Duration(days: 8))),
          ChatMessage(id: '7', text: 'You still interested in the DAO proposal?', isUser: false, timestamp: now.subtract(const Duration(days: 8, hours: -2))),
          ChatMessage(id: '8', text: 'Let me know when you\'re free!', isUser: false, timestamp: now.subtract(const Duration(days: 8, hours: -4))),
          ChatMessage(id: '9', text: 'Dude???', isUser: false, timestamp: now.subtract(const Duration(days: 8, hours: -6))),
          ChatMessage(id: '10', text: 'I guess you\'re busy', isUser: false, timestamp: now.subtract(const Duration(days: 8, hours: -8))),
        ],
      ),
      
      // Person 2: Sent 6 messages, NO REPLY - Should have LOW health score
      // Person 2: Many unanswered messages - Should have LOW health score
      Conversation(
        id: '2',
        contactName: 'Sarah Martinez',
        platform: ChatPlatform.telegram,
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
        lastMessageTime: now.subtract(const Duration(days: 8)),
        hasUnread: true,
        messages: [
          ChatMessage(id: '1', text: 'Yo! That token launch was insane', isUser: false, timestamp: now.subtract(const Duration(days: 18))),
          ChatMessage(id: '2', text: 'I know right! Did you get in?', isUser: true, timestamp: now.subtract(const Duration(days: 18, hours: -1))),
          ChatMessage(id: '3', text: 'Yeah got a small bag', isUser: false, timestamp: now.subtract(const Duration(days: 17))),
          ChatMessage(id: '4', text: 'GM! How\'s the bull run treating you?', isUser: false, timestamp: now.subtract(const Duration(days: 15))),
          ChatMessage(id: '5', text: 'That airdrop we discussed is live btw', isUser: false, timestamp: now.subtract(const Duration(days: 14))),
          ChatMessage(id: '6', text: 'You claimed yours yet?', isUser: false, timestamp: now.subtract(const Duration(days: 13))),
          ChatMessage(id: '7', text: 'Also wanted to ask about your DeFi portfolio', isUser: false, timestamp: now.subtract(const Duration(days: 12))),
          ChatMessage(id: '8', text: 'The APY on that pool is insane', isUser: false, timestamp: now.subtract(const Duration(days: 12, hours: -3))),
          ChatMessage(id: '9', text: 'Yo you good? Haven\'t heard from you', isUser: false, timestamp: now.subtract(const Duration(days: 12, hours: -5))),
          ChatMessage(id: '10', text: 'Hit me up when you can', isUser: false, timestamp: now.subtract(const Duration(days: 12, hours: -7))),
        ],
      ),
      
      // Person 5: Unanswered - Should have LOW health score  
      Conversation(
        id: '5',
        contactName: 'David Lee',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=68',
        lastMessageTime: now.subtract(const Duration(days: 20)),
        hasUnread: true,
        messages: [
          ChatMessage(id: '1', text: 'Hey man! Long time', isUser: false, timestamp: now.subtract(const Duration(days: 25))),
          ChatMessage(id: '2', text: 'Remember that Web3 project we talked about?', isUser: false, timestamp: now.subtract(const Duration(days: 24))),
          ChatMessage(id: '3', text: 'I found a developer who wants to join', isUser: false, timestamp: now.subtract(const Duration(days: 23))),
          ChatMessage(id: '4', text: 'You still down to build?', isUser: false, timestamp: now.subtract(const Duration(days: 22))),
          ChatMessage(id: '5', text: 'Bro????', isUser: false, timestamp: now.subtract(const Duration(days: 21))),
          ChatMessage(id: '6', text: 'Guess you\'re busy', isUser: false, timestamp: now.subtract(const Duration(days: 20))),
          ChatMessage(id: '7', text: 'Hit me up when you see this', isUser: false, timestamp: now.subtract(const Duration(days: 20, hours: -2))),
        ],
      ),
      
      // Person 4: Good back and forth conversation - Should have GOOD health score
      Conversation(
        id: '4',
        contactName: 'Emily Rodriguez',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=28',
        lastMessageTime: now.subtract(const Duration(hours: 3)),
        hasUnread: false,
        messages: [
          ChatMessage(id: '1', text: 'Yo! Check out this new DApp', isUser: false, timestamp: now.subtract(const Duration(days: 2))),
          ChatMessage(id: '2', text: 'Oh nice! Is it on Solana?', isUser: true, timestamp: now.subtract(const Duration(days: 2, hours: -1))),
          ChatMessage(id: '3', text: 'Yeah! And the UI is fire', isUser: false, timestamp: now.subtract(const Duration(days: 1))),
          ChatMessage(id: '4', text: 'I\'ll check it out tonight', isUser: true, timestamp: now.subtract(const Duration(days: 1, hours: -2))),
          ChatMessage(id: '5', text: 'Also, congrats on your recent launch!', isUser: false, timestamp: now.subtract(const Duration(hours: 10))),
          ChatMessage(id: '6', text: 'Thanks! Been grinding hard', isUser: true, timestamp: now.subtract(const Duration(hours: 8))),
          ChatMessage(id: '7', text: 'We should collab on something', isUser: false, timestamp: now.subtract(const Duration(hours: 5))),
          ChatMessage(id: '8', text: 'Absolutely! Let\'s brainstorm', isUser: true, timestamp: now.subtract(const Duration(hours: 3))),
        ],
      ),
      
      // Person 6: Balanced conversation - Should have MEDIUM health score
      Conversation(
        id: '6',
        contactName: 'Nikita Patel',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
        lastMessageTime: now.subtract(const Duration(days: 5)),
        hasUnread: false,
        messages: [
          ChatMessage(id: '1', text: 'GM! Ready for the next mint?', isUser: false, timestamp: now.subtract(const Duration(days: 8))),
          ChatMessage(id: '2', text: 'Always! What project?', isUser: true, timestamp: now.subtract(const Duration(days: 8, hours: -2))),
          ChatMessage(id: '3', text: 'That generative art collection', isUser: false, timestamp: now.subtract(const Duration(days: 7))),
          ChatMessage(id: '4', text: 'Oh yeah! Public mint tomorrow?', isUser: true, timestamp: now.subtract(const Duration(days: 7, hours: -3))),
          ChatMessage(id: '5', text: 'Yep! Getting my SOL ready', isUser: false, timestamp: now.subtract(const Duration(days: 6))),
          ChatMessage(id: '6', text: 'Same. Hope we both hit!', isUser: true, timestamp: now.subtract(const Duration(days: 5))),
        ],
      ),
      
      // Person 7: Good active conversation
      Conversation(
        id: '7',
        contactName: 'Ryan Thompson',
        platform: ChatPlatform.telegram,
        avatarUrl: 'https://i.pravatar.cc/150?img=14',
        lastMessageTime: now.subtract(const Duration(hours: 4)),
        hasUnread: false,
        messages: [
          ChatMessage(id: '1', text: 'Deploying the smart contract today', isUser: false, timestamp: now.subtract(const Duration(days: 3))),
          ChatMessage(id: '2', text: 'Nice! On testnet first right?', isUser: true, timestamp: now.subtract(const Duration(days: 3, hours: -1))),
          ChatMessage(id: '3', text: 'Of course! Safety first', isUser: false, timestamp: now.subtract(const Duration(days: 2))),
          ChatMessage(id: '4', text: 'Learned that the hard way lol', isUser: true, timestamp: now.subtract(const Duration(days: 2, hours: -2))),
          ChatMessage(id: '5', text: 'Haha same. Tests passed!', isUser: false, timestamp: now.subtract(const Duration(days: 1))),
          ChatMessage(id: '6', text: 'Congrats! Ready for mainnet?', isUser: true, timestamp: now.subtract(const Duration(hours: 5))),
          ChatMessage(id: '7', text: 'Going live in 1 hour', isUser: false, timestamp: now.subtract(const Duration(hours: 4))),
        ],
      ),
      
      // Person 8: Sent 3 messages, NO REPLY
      Conversation(
        id: '8',
        contactName: 'Chris Anderson',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
        lastMessageTime: now.subtract(const Duration(days: 10)),
        hasUnread: true,
        messages: [
          ChatMessage(id: '1', text: 'Yo! Saw your mint', isUser: false, timestamp: now.subtract(const Duration(days: 11))),
          ChatMessage(id: '2', text: 'Wanna trade? I got a legendary', isUser: false, timestamp: now.subtract(const Duration(days: 10))),
          ChatMessage(id: '3', text: 'Lmk if interested!', isUser: false, timestamp: now.subtract(const Duration(days: 10, hours: -4))),
        ],
      ),
      
      // Person 9: Regular conversation
      Conversation(
        id: '9',
        contactName: 'David Kim',
        platform: ChatPlatform.telegram,
        avatarUrl: 'https://i.pravatar.cc/150?img=51',
        lastMessageTime: now.subtract(const Duration(days: 2)),
        hasUnread: false,
        messages: [
          ChatMessage(id: '1', text: 'That yield farm looking juicy', isUser: false, timestamp: now.subtract(const Duration(days: 4))),
          ChatMessage(id: '2', text: 'APY went up to 200%?!', isUser: true, timestamp: now.subtract(const Duration(days: 4, hours: -1))),
          ChatMessage(id: '3', text: 'Yeah but high risk obviously', isUser: false, timestamp: now.subtract(const Duration(days: 3))),
          ChatMessage(id: '4', text: 'True. DYOR always', isUser: true, timestamp: now.subtract(const Duration(days: 3, hours: -2))),
          ChatMessage(id: '5', text: 'Only putting in what I can lose', isUser: false, timestamp: now.subtract(const Duration(days: 2))),
          ChatMessage(id: '6', text: 'Smart move. Good luck anon!', isUser: true, timestamp: now.subtract(const Duration(days: 2))),
        ],
      ),
      
      // Person 10: Sent 5 messages, NO REPLY  
      Conversation(
        id: '10',
        contactName: 'Jenny Liu',
        platform: ChatPlatform.discord,
        avatarUrl: 'https://i.pravatar.cc/150?img=41',
        lastMessageTime: now.subtract(const Duration(days: 16)),
        hasUnread: true,
        messages: [
          ChatMessage(id: '1', text: 'Bro the metaverse event is this weekend', isUser: false, timestamp: now.subtract(const Duration(days: 18))),
          ChatMessage(id: '2', text: 'You coming to the VR meetup?', isUser: false, timestamp: now.subtract(const Duration(days: 17))),
          ChatMessage(id: '3', text: 'Free NFT wearables for attendees!', isUser: false, timestamp: now.subtract(const Duration(days: 16))),
          ChatMessage(id: '4', text: 'Would be cool to hang out', isUser: false, timestamp: now.subtract(const Duration(days: 16, hours: -4))),
          ChatMessage(id: '5', text: 'Guess you\'re busy :/', isUser: false, timestamp: now.subtract(const Duration(days: 16, hours: -6))),
        ],
      ),
    ];
  }
}

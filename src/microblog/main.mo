import Array "mo:base/Array";
import Time "mo:base/Time";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

actor {
    public type Message = {
        content: Text;
        time: Int;
    };
    public type Microblog = actor {
        follow: shared(Principal) -> async ();//添加关注
        follows: shared query() -> async [Principal];//返回关注列表
        post: shared(Message) -> async ();//发布post
        posts: shared query(Time.Time) -> async [Message];// 返回所有发布的消息
        timeline: shared(Time.Time) -> async [Message];//返回所有关注对象的发布消息
    };

    var people: List.List<Principal> = List.nil();
    var messages: List.List<Message> = List.nil();

    public shared({caller}) func follow(id: Principal): async () {
        people := List.push(id, people);
    };
    
    public query({caller}) func follows(): async [Principal] {
        return List.toArray(people);
    };

    public shared({caller}) func post(content: Text): async () {
        let message = {
            content = content;
            time = Time.now();
        };
        messages := List.push(message, messages);
    };

    public query({caller}) func posts(since: Time.Time): async [Message] {
        var ans: [Message] = [];
        label L for(message in Iter.fromList(messages)) {
            if(message.time < since) continue L;
            ans := Array.append(ans, [message]);
        };
        return ans;
    };

    public shared({caller}) func timeline(since: Time.Time): async [Message] {
        var ans: [Message] = [];
        for(id in Iter.fromList(people)) {
            let canister: Microblog = actor(Principal.toText(id));
            let ans_messages = await canister.posts(since);
            ans := Array.append(ans, ans_messages); 
        };
        return ans;
    };
};
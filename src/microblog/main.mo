import Array "mo:base/Array";
import Time "mo:base/Time";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

actor {
    public type Message = {
        author: Text;
        content: Text;
        time: Int;
    };
    public type Microblog = actor {
        follow: shared(Principal) -> async ();//添加关注
        follows: shared query() -> async [Principal];//返回关注列表
        post: shared(Message) -> async ();//发布post
        posts: shared query(Time.Time) -> async [Message];// 返回所有发布的消息
        timeline: shared(Time.Time) -> async [Message];//返回所有关注对象的发布消息
        set_name: shared(Text) -> async ();
        get_name: shared() -> async Text;
    };

    var people: List.List<Principal> = List.nil();
    var messages: List.List<Message> = List.nil();
    var author_name: Text = "not set the author name!";

    public shared func follow(id: Principal): async () {
        people := List.push(id, people);
    };
    
    public query func follows(): async [Principal] {
        return List.toArray(people);
    };

    public query func get_name(): async Text {
        return author_name;
    };

    public shared func set_name(new_name: Text): async () {
        author_name := new_name;
    };

    public shared func post(content: Text): async () {
        let message = {
            author = author_name;
            content = content;
            time = Time.now();
        };
        messages := List.push(message, messages);
    };

    public query func posts(since: Time.Time): async [Message] {
        var ans: [Message] = [];
        label L for(message in Iter.fromList(messages)) {
            if(message.time < since) continue L;
            ans := Array.append(ans, [message]);
        };
        return ans;
    };

    public shared func timeline(since: Time.Time): async [Message] {
        var ans: [Message] = [];
        for(id in Iter.fromList(people)) {
            let canister: Microblog = actor(Principal.toText(id));
            let ans_messages = await canister.posts(since);
            ans := Array.append(ans, ans_messages); 
        };
        return ans;
    };
};
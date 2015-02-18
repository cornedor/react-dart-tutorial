import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:react/react_client.dart' as reactClient;
import 'package:react/react.dart';
import 'package:markdown/markdown.dart';

var comment = registerComponent(() => new Comment());
var commentList = registerComponent(() => new CommentList());
var commentForm = registerComponent(() => new CommentForm());
var commentBox = registerComponent(() => new CommentBox());

class Comment extends Component {
  get author => props['author'];
  get children => props['children'];
  render() {
    String rawMarkup = markdownToHtml(children[0].toString());
    return div({'className': 'comment'}, [
        h2({'className': 'commentAuthor'}, author),
        span({'dangerouslySetInnerHTML': {'__html': rawMarkup}})
    ]);
  }
}

class CommentList extends Component {
  render() {
    List data = props['data'];
    var commentNodes = data.map((item) {
      return comment({'author': item['author']}, item['text']);
    }).toList();
    
    return div({'className': 'commentList'}, commentNodes);
  }
}

class CommentForm extends Component {
  get onCommentSubmit => props['onCommentSubmit'];
  
  void handleSubmit(SyntheticFormEvent e) {
    e.preventDefault();
    String author = ref('author').value;
    String text = ref('text').value;
    if(text.isEmpty || author.isEmpty) {
      return;
    }
    
    onCommentSubmit({'author': author, 'text': text});
    
    ref('author').value = '';
    ref('text').value = '';
  }
  
  render() {
    return form({'className': 'commentForm', 'onSubmit': handleSubmit}, [
        input({'type': 'text', 'placeholder': 'Your name', 'ref': 'author'}),
        input({'type': 'text', 'placeholder': 'Say something...', 'ref': 'text'}),
        input({'type': 'submit', 'value': 'Post'})
    ]);
  }
}

class CommentBox extends Component {
  get url => props['url'];
  get pollInterval => props['pollInterval'];
  
  void loadCommentsFromServer() {
    HttpRequest.getString(url)
        .then((String contents) {
          setState({'data': JSON.decode(contents)});
        })
        .catchError((Error error) {
          print("Request to ${url} failed with error: ${error.toString}");
        });
  }
  
  void handleCommentSubmit(comment) {
    List comments = state['data'];
    List newComments = comments..addAll([comment]);
    setState({'data': newComments});
    HttpRequest.postFormData(url, comment)
        .then((HttpRequest req) {
          setState({'data': JSON.decode(req.response.toString())});
        })
        .catchError((error) {
          print("Request to ${url} failed with error: ${error.toString}");
        });
  }
  
  Map getInitialState() {
    return {'data': []};
  }
  
  void componentDidMount(rootNode) {
    loadCommentsFromServer();
    new Timer.periodic(new Duration(milliseconds: pollInterval), (Timer timer) => loadCommentsFromServer());
  }
  
  render() {
    return div({'className': 'commentBox'}, [
        commentList({'data': state['data']}),
        commentForm({'onCommentSubmit': handleCommentSubmit})
    ]);
  }
}

void main() {
  reactClient.setClientConfiguration();
  render(commentBox({'url': 'http://localhost:3000/comments.json', 'pollInterval': 2000}), querySelector('#content'));
}

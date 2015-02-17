import 'dart:html';
import 'dart:convert';

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
  render() {
    return div({'className': 'commentForm'}, 'Hello, world! I am a CommentForm');
  }
}

class CommentBox extends Component {
  get url => props['url'];
  Map getInitialState() {
    return {'data': []};
  }
  
  void componentDidMount(rootNode) {
    HttpRequest.getString(url)
        .then((String contents) {
          setState({'data': JSON.decode(contents)});
        })
        .catchError((Error error) {
          window.alert('HttpRequest error');
        });
  }
  
  render() {
    return div({'className': 'commentBox'}, [commentList({'data': state['data']}), commentForm({})]);
  }
}

void main() {
  reactClient.setClientConfiguration();
  var data = [
      {'author': 'Pete Hunt', 'text': 'This is one comment'},
      {'author': 'Jordan Walke', 'text': 'This is *another* comment'}
  ];
  render(commentBox({'url': 'comments.json'}), querySelector('#content'));
}

class News {
  String _author;

  String get author => _author;
  String _title;
  String _description;
  String _url;
  String _urlToImage;
  String _publishedAt;
  String _content;
  String _source;

  News(  {String author,
  String title,
  String description,
  String url,
  String urlToImage,
  String publishedAt,
  String content,
  String source}) {
    this._title = title;
    this._author = author;
    this._description = description;
    this._url = url;
    this._urlToImage = urlToImage;
    this._publishedAt = publishedAt;
    this._content = content;
    this._source = source;

  }


  factory News.fromJson(Map<String, dynamic> parsedJson){
    return News(
        title: parsedJson['title'].toString(),
        author : parsedJson['author'].toString(),
        description: parsedJson['description'].toString(),
        url: parsedJson['url'].toString(),
        urlToImage: parsedJson['urlToImage'].toString(),
        publishedAt: parsedJson['publishedAt'].toString(),
        content: parsedJson['content'].toString(),
        source: parsedJson['source']['name'].toString()
    );
  }

  String get title => _title;

  String get description => _description;

  String get url => _url;

  String get urlToImage => _urlToImage;

  String get publishedAt => _publishedAt;

  String get content => _content;

  String get source => _source;

}



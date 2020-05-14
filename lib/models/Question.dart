class Question {
  String _questionText;
  String _image;
  List<String> _response;

  Question(String questionText, String image, List<String> response) {
    this._questionText = questionText;
    this._image = image;
    this._response = response;
  }

  String get questionText => _questionText;

  String get image => _image;

  List<String> get response => _response;
}

class Result {
  String _text;
  String _key;
  String _image;
  String _moreText;

  Result(String text, String image, String key, String moreText) {
    this._text = text;
    this._key = key;
    this._image = image;
    this._moreText = moreText;
  }

  String get text => _text;

  String get key => _key;

  String get image => _image;

  String get moreText => _moreText;
}

enum ResultKey { SEVERE, HIGH, MEDIUM, LOW }

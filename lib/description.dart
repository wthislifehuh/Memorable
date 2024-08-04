class Description {
  String objectName;
  int index;
  String title;
  String description;
  String user;
  int like;
  int dislike;
  String image = "";
  String uri = "";

  Description(this.objectName, this.index, this.title, this.description,
      this.user, this.like, this.dislike, this.image, this.uri);

  Description.addNew(this.objectName, this.index, this.title, this.description,
      this.user, this.image)
      : this.like = 0,
        this.dislike = 0;

  String getUri() {
    return this.uri;
  }
}

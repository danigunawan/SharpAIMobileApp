Template.collectList.helpers({
  collectList: function () {
    var list = SimpleChat.CollectMessages.find({}).fetch();
    return list;
  },
  
});

Template.collectItem.helpers({
  isImage: function(type) {
    return type === 'image';
  },
  name: function() {
    if (this.form.id !== Meteor.userId) {
      return this.form.name;
    } else {
      return this.to.name;
    }
  },
  collectDate: function() {
    var date = new Date(this.collectDate);
    var year = date.getFullYear();
    var month = date.getMonth() + 1;
    var day = date.getDate();
    var dateStr = year + '/' + month + '/' + day;
    return dateStr;
  }
});

Template.collectList.events({
  'click .back': function(e) {
    return Router.go('/user');
  },
});

Template.collectItem.events({
  'click .delBtn': function(e) {
    SimpleChat.CollectMessages.remove({_id: this._id});
  },
});

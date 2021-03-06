
SSR.compileTemplate('srvemailTemplate', Assets.getText('srvemail-template.html'));

Template.srvemailTemplate.onCreated(function helloOnCreated() {
  
});

Template.srvemailTemplate.helpers({
  company_name() {
    group_id = CurrentGroupId
    group = SimpleChat.Groups.findOne({_id:group_id});
    
    return group.name
  },
  job_date2(){
    group_id = CurrentGroupId
    group = SimpleChat.Groups.findOne({_id:group_id});
    
    if (group == null){
      return ""
    }
    
    now = new Date()
    localDate = LocalDateTimezone(now, group.offsetTimeZone);
    console.log(localDate.getFullYear(), localDate.getMonth() , localDate.getDate(), 
      localDate.getHours(), localDate.getMinutes(), localDate.getSeconds())

    return localDate.getFullYear()+ "-"+ localDate.getMonth() + "-" + localDate.getDate() 
  }
});

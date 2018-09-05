//0:刚进入显示开始 1:点击开始后显示结束按钮
var btn_pro = new ReactiveVar(0);
var markList = new ReactiveVar([]);
Session.set("isMark", true)

var datas = null
// $.get('http://192.168.31.113:5000/api/parameters', function(data){
//     datas = data
// })
// Date.prototypeishaveStranger.Format = function(fmt) {
//     var o = {
//         "M+": this.getMonth() + 1,
//         "d+": this.getDate(),
//         "h+": this.getHours(),
//         "m+": this.getMinutes(),
//         "s+": this.getSeconds(),
//         "q+": Math.floor((this.getMonth() + 3) / 3),
//         "S": this.getMilliseconds()
//     };
//     if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
//     for (var k in o)
//         if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
//     return fmt;
// }

Template.haveStranger.events({
    'click .back': function(e) {
        btn_pro.set(0);
        return PUB.back();
    },
    'click .skip p': function(e){
        return PUB.back()
        //return PUB.page("/_simpleChatToChat")
    },
    'click .stranges-item': function(e, t) {
        var sessionType = Session.get("session_type")
        var toUserId = Session.get("toUser_id")
        var url = '/simple-chat/to/' + sessionType + '?id=' + toUserId
        var tagName = $(e.target).prop("tagName").toLowerCase()
        var $li = $(e.currentTarget)
        var id = $li.attr("data")
        if (tagName === "a" || tagName === "i") {
            if ($(e.target).attr("id") === "reject" || $(e.target).parent().attr("id") === "reject") {
                Session.set("isMark", true)
                Strangers.remove({ _id: id })
                var len = Strangers.find({ group_id: { $eq: Session.get("toUser_id") } }).fetch().length
                $('#stranger-contain').find($li).remove()
                if (len == 0) {
                    PUB.page(url)
                }
            } else {
                var curData = Strangers.find({ _id: id }).fetch()[0].imgs
                Session.set("isMark", false)
                markList.set(curData)
            }
        }
        if (((tagName === "a" || tagName === "i")) && ($(e.target).attr("id") === "accept" || $(e.target).parent().attr("id") === "accept")) {
            var imgData = markList.get()
            var val = $("#mark_val").val()
            var uuid = this.uuid
            var id = this._id
            var group_id = this.group_id
            // imgData = JSON.parse(imgData)
            // var faceId = new Mongo.ObjectID()._str
            Session.set("isMark", true)

            var call_back_handle = function(name) {
                if (!name) {
                    return;
                }

                PUB.showWaitLoading('处理中');
                var setNames = [];
                Meteor.call('get-id-by-name1', uuid, name, group_id, function(err, res) {
                    if (err || !res) {
                        return PUB.toast('标注失败，请重试');
                    }

                    var faceId = null;
                    if (res && res.faceId) {
                        faceId = res.faceId;
                    } else if (imgData[0].person_name != null && imgData[0].person_name != undefined) {
                        faceId = new Mongo.ObjectID()._str;
                    } else {
                        faceId = imgData[0].faceid;
                    }

                    imgData.forEach(function(item) {
                        // 发送消息给平板
                        var trainsetObj = {
                            group_id: group_id,
                            type: 'trainset',
                            url: item.url,
                            person_id: item.faceid,
                            device_id: uuid,
                            face_id: faceId,
                            drop: false,
                            img_type: 'face',
                            style: item.style,
                            sqlid: item.sqlid
                        };
                        console.log("==sr==. timeLine multiSelect: " + JSON.stringify(trainsetObj));
                        sendMqttMessage('/device/' + group_id, trainsetObj);

                        setNames.push({
                            uuid: uuid,
                            id: faceId, //item.person_id,
                            url: item.url,
                            name: name,
                            sqlid: item.style,
                            style: item.sqlid
                        });
                    });

                    if (setNames.length > 0) {
                        Meteor.call('set-person-names', group_id, setNames);
                    }
                    imgData.forEach(function(item) {
                        try {
                            var person_info = {
                                'uuid': uuid,
                                'name': name,
                                'group_id': group_id,
                                'img_url': item.url,
                                'type': 'face',
                                'ts': new Date().getTime(),
                                'accuracy': item.accuracy,
                                'fuzziness': item.fuzziness,
                                'sqlid': item.sqlid,
                                'style': item.style
                            };
                            var data = {
                                face_id: item.faceid,
                                person_info: person_info,
                                formLabel: true
                            };

                            Meteor.call('ai-checkin-out', data, function(err, res) {

                            });
                        } catch (e) {}
                    });
                    PUB.hideWaitLoading();
                    Strangers.remove({ _id: id })
                    //Meteor.call('removeStrangers', id)
                    var len = Strangers.find({ group_id: { $eq: Session.get("toUser_id") } }).fetch().length
                    $('#stranger-contain').find($li).remove()
                    if (len == 0) {
                        PUB.page(url)
                    }
                });
            };
            SimpleChat.show_label(group_id, this.avatar, call_back_handle);
        }
    }
})

Template.haveStranger.helpers({
    isHaveStranger: function() {
        if (Strangers.find().count() > 0)
            return true;
        return false;
    },
    Stranger_people: function() {
        try {
            var face_list = Session.get("face_list")//获得设置的是正脸还是侧脸
            var fuzziness = Session.get("fuzziness")//获得设置的清晰度
            var str = new Object();//此对象储存筛选出来的数据
            if(face_list && face_list.length >= 0 && fuzziness != ""){
                //如果设置了人脸过滤阈值就按照此条件搜索
                st = Strangers.find({ group_id: { $eq: Session.get("toUser_id")}}, {style:{$or:face_list[0]},style:{$or:face_list[1]},style:{$or:face_list[2]} })
                for(x in st) {
                    var fuzziness_num = Math.floor(x.fuzziness)
                    if(fuzziness_num == fuzziness){
                        str += st[x];//储存筛选出来的数据
                    }
                }
                return str
            }else if(face_list.length <= 0 && fuzziness == ""){
                st = Strangers.find({ group_id: { $eq: Session.get("toUser_id")}})
            }else{
                st = Strangers.find({ group_id: { $eq: Session.get("toUser_id")}})
                PUB.page("您设置的阙值未匹配到！")
            }
        } catch (error) {
            st = Strangers.find({ group_id: { $eq: Session.get("toUser_id")}})
        }
        return st
    },
    isMark: function() {
        return Session.get("isMark")
    }
})
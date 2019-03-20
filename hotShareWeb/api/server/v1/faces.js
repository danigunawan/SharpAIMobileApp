var api = require('../api.js');

var Api = api.ApiV1;

function insertFace(params) {
  var doc = {
    uuid:       params.uuid,
    name:       params.name,
    group_id:   params.groupId,
    img_url:    params.imgUrl,
    position:   params.position,
    type:       'face',
    current_ts: new Date().getTime(),
    accuracy:   params.accuracy,
    fuzziness:  params.fuzziness,
    sqlid:      params.sqlid,
    style:      params.style || 'front',
    tid:        params.tid,
    img_ts:     params.img_ts,
    p_ids:      params.p_ids,
    createdAt:  new Date()
  };

  doc.id = doc.current_ts + doc.uuid;

  var device = Devices.findOne({
    uuid: doc.uuid
  });
  if (device && device.name) {
    doc.device_name = device.name;
  }

  var faceId = Faces.insert(doc);

  return Faces.findOne(faceId);
}

// TODO: person.js 有相应method ”set-person-names“，但是不通用，后期可优化
function label(groupId, items, action = '用户API上传标记') {
  if (!_.isArray(items)) return;

  PERSON.updateLabelTimes(groupId, items);

  _.each(items, function (item) {
    var person = PERSON.setName(groupId, item.uuid, item.faceId, item.imgUrl, item.name);
    var labelInfo = {
      group_id: groupId,
      uuid:     item.uuid,
      id:       item.faceId,
      url:      item.imgUrl,
      name:     item.name,
      sqlid:    item.sqlid,
      style:    item.style,
      action:   action
    };

    LABLE_DADASET_Handle.insert(labelInfo);

    var trainsetObj = _.defaults({
      type:     'trainset',
      person_id: person._id,
      device_id: person.deviceId,
      face_id:   person.faceId,
      drop:      false,
      img_type:  'face',
    }, labelInfo);

    sendMqttMessage('/device/' + groupId, trainsetObj);
  });
}

function checkFaceData(face) {
  console.log(face);
  var imgUrl = face.imgUrl && face.imgUrl.trim();
  var uuid   = face.uuid && face.uuid.trim();
  var name   = face.name && face.name.trim();

  if (!imgUrl || !uuid || !name) {
    throw new Meteor.Error('error-faces-param-not-provided', 'The parameter "imgUrl" or "uuid" or "name" is required');
  }

  if (!Devices.findOne({uuid: uuid})) {
    throw new Meteor.Error('error-deivce-not-existed', 'Device(' + uuid + ')  do not exist!');
  }
}

/**
 * 
 * 标注单张
 * @urlParam groupId {string}
 * @bodyParam
 * {
 *    "imgurl":     图片地址, (必填)
 *    "uuid":       设备Id (必填)
 *    "name":       标注名称 (必填)
 *    "position":   位置 (选填)
 *    "type":       类型.默认:face (选填)
 *    "current_ts": 当前时间 毫秒 (选填)
 *    "accuracy":   图片精准度 (选填)
 *    "fuzziness":  图片模糊度 (选填)
 *    "sqlid":      本地sqlid (选填)
 *    "style":      人脸类型(前脸 front,左脸 left_side,右脸right_side)。默认:front (选填)
 *    "tid":        连续图片id (选填)
 *    "img_ts":     图片拍摄时间 毫秒 (选填)
 *    "p_ids":      同一时间拍摄的多张图片 (选填)
 * }
 */
Api.addRoute('groups/:groupId/faces', {
  authRequired: false
}, {
  post: function () {
    try {
      var groupId = this.urlParams.groupId && this.urlParams.groupId.trim();
      if (!groupId) {
        throw new Meteor.Error('error-group-faces-param-not-provided', 'The parameter "groupId" is required');
      }

      if (!SimpleChat.Groups.findOne(groupId)) {
        throw new Meteor.Error('error-group-not-existed', 'Group(' + groupId + ') do not exist!');
      }

      var params = this.bodyParams;
      checkFaceData(params);

      var face = insertFace(params);
      var item = {
        uuid: face.uuid,
        faceId: face.id,
        imgUrl: face.img_url,
        name: face.name,
        sqlid: face.sqlid,
        style: face.style
      };

      // 标注训练
      label(groupId, [item]);

      return api.success();
    } catch (e) {
      return api.failure(e.message, e.error);
    }
  }
});

/**
 * 
 * batch
 * @urlParam  groupId {string}
 * @bodyParam 
 * {
 *   "create": [
 *      {obj1(格式同标注单张 bodyParam)},
 *      {obj2(格式同标注单张 bodyParam)},
 *      ... 
 *   ]
 * }
 */
Api.addRoute('groups/:groupId/faces/batch', {
  authRequired: false
}, {
  post: function () {
    try {
      var groupId = this.urlParams.groupId && this.urlParams.groupId.trim();
      if (!groupId) {
        throw new Meteor.Error('error-group-faces-param-not-provided', 'The parameter "groupId" is required');
      }

      if (!SimpleChat.Groups.findOne(groupId)) {
        throw new Meteor.Error('error-group-not-existed', 'Group(' + groupId + ') do not exist!');
      }

      var params = this.bodyParams;
      if (_.isEmpty(params) || _.isEmpty(params.create)) {
        throw new Meteor.Error('error-faces-param-not-provided', 'The parameter " " is required');
      }

      var items = [];
      _.each(params.create, function (param) {
        checkFaceData(param);

        var face = insertFace(param);
        console.log(face);
        var item = {
          uuid: face.uuid,
          faceId: face.id,
          imgUrl: face.img_url,
          name: face.name,
          sqlid: face.sqlid,
          style: face.style
        };

        items.push(item);
      });

      Meteor.setTimeout(function() { 
        label(groupId, items);
      }, 200);
      
      return api.success();
    } catch (e) {
      return api.failure(e.message, e.error);
    }
  }
});

// get
Api.addRoute('faces/:id', {
  authRequired: false
}, {
  get: function () {
    try {
      var id = this.urlParams.id && this.urlParams.id.trim();

      if (!id) {
        throw new Meteor.Error('error-faces-param-not-provided', 'The parameter "id" is required');
      }

      var result = Faces.findOne({
        id: id
      });

      return _.isEmpty(result) ? api.success({
        result: '未找到结果'
      }) : result;
    } catch (e) {
      return api.failure(e.message, e.error);
    }
  }
});
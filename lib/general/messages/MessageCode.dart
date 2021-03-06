enum MessageCode {
  SignUp,
  EmailAlreadyInUse,
  SuccessfulSignUp,
  ConfirmEmail,
  UserNotFound,
  InvalidConfirmationCode,
  LogIn,
  SuccessfulLogIn,
  Join,
  Joined,
  Disconnect,
  CreateShareRoom,
  SuccessfulShareRoomCreation,
  NoPalsInRoom,
  ShareRoomInvitation,
  CreateShareItem,
  GetUsers,
  SearchUsers,
  Users,
  AddFirebaseUser,
  SuccessfulFirebaseUserAdding,
  RoomNotFound,
  SuccessfulShareItemCreation,
  NewShareItem,
  NewPals,
  AckRoomMembershipOperation,
  InvitedToShareRoom,
  SuccessfulInvitation,
  LeaveRoom,
  PalLeft,
  SuccessfulLeaving,
  AckReceive,
  AckRead,
  AckReceiveRead,
  DeleteAcks,
  ItemNotFound,
  AckedReceive,
  AckedRead,
  AckedReceiveRead,
  IsTyping,
  ClientError,
  ServerError,
  UserOffline,

  WebRtcInquire,
  WebRtcInquireSuccess,
  WebRtcGrant,
  WebRtcRefuse,
  WebRtcOffer,
  WebRtcOfferSuccess,
  WebRtcAnswer,
  WebRtcAnswerSuccess,
  WebRtcCandidate,
  WebRtcCandidateSuccess,
  WebRtcDecline,
  WebRtcEndSession,
  WebRtcCancel,
  WebRtcError,
}

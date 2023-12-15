import { TUser } from '@domain/users'

export interface IUserDetailsProps extends TUser {
  isMyself: boolean
  onHandleOpenChatDialog: (user: TUser) => void
}

export class BlogCommentViewModel {

    constructor(

        public blogCommentId: number,
        public blogId: number,
        public content: string,
        public username: string,
        public publishDate: Date | null,
        public updateDate: Date | null,
        public isEditable: boolean = false,
        public deleteConfirm: boolean = false,
        public isReplying: boolean = false,
        public comments: BlogCommentViewModel[],
        public parentBlogCommentId?: number | null,
    ) {}
}
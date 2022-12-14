import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, map, Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApplicationUsercreate } from '../models/account/application-user-create.model';
import { ApplicationUserLogin } from '../models/account/application-user-login.model';
import { ApplicationUser } from '../models/account/application-user.model';

@Injectable({
  providedIn: 'root'
})
export class AccountService {

  private currentUserSubject$: BehaviorSubject<ApplicationUser | null>

  constructor(
    private http: HttpClient
    ) { 
      this.currentUserSubject$ = new BehaviorSubject<ApplicationUser | null>(JSON.parse(localStorage.getItem('blogLab-currentUser')!));
    }
  
  login(model: ApplicationUserLogin) : Observable<ApplicationUser> {
    return this.http.post<ApplicationUser>(`${environment.webApi}/Account/login`, model)
    .pipe(
      map((user : ApplicationUser) => {

        if (user) {
          localStorage.setItem('blogLab-currentUser', JSON.stringify(user));
          this.setCurrentUser(user);
        }

        return user;
      })
    )
  }

  setCurrentUser(user: ApplicationUser) {
    this.currentUserSubject$.next(user);
  }

  public get currentUserValue(): (ApplicationUser | null) {
    return this.currentUserSubject$.value;
  }

  register(model: ApplicationUsercreate) : Observable<ApplicationUser> {
    return this.http.post<ApplicationUser>(`${environment.webApi}/Account/register`, model)
    .pipe(
      map((user : ApplicationUser) => {

        if (user) {
          localStorage.setItem('blogLab-currentUser', JSON.stringify(user));
          this.setCurrentUser(user);
        }

        return user;
      })
    )
  }

  public isLoggedIn() : boolean {
    const currentUser = this.currentUserValue;
    const isLoggedIn = !!currentUser && !!currentUser.token;

    return isLoggedIn;
  }

  logout() {
    localStorage.removeItem('blogLab-currentUser');
    this.currentUserSubject$.next(null);
  }

  public givenUserIsLoggedIn(username: string) : boolean {
    return this.isLoggedIn() && this.currentUserValue?.username === username;
  }
} 

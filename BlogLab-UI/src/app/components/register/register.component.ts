import { Component, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ValidatorFn, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ApplicationUsercreate } from 'src/app/models/account/application-user-create.model';
import { AccountService } from 'src/app/services/account.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent implements OnInit {

  registerForm!: FormGroup;

  constructor(
    private accountService: AccountService,
    private router: Router,
    private formBuilder: FormBuilder
  ) { 
    
    }

    ngOnInit(): void {
      this.registerForm = this.formBuilder.group({
        fullname: [null, [
          Validators.minLength(10),
          Validators.maxLength(30)
        ]],
        username: [null, [
          Validators.required,
          Validators.minLength(5),
          Validators.maxLength(20)
        ]],
        email: [null, [
          Validators.required,
          Validators.pattern("([-!#-'*+/-9=?A-Z^-~]+(\\.[-!#-'*+/-9=?A-Z^-~]+)*|\"([]!#-[^-~ \\t]|(\\[\\t -~]))+\")@([0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?(\\.[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?)*|\\[((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}|IPv6:((((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){6}|::((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){5}|[0-9A-Fa-f]{0,4}::((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){4}|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):)?(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){3}|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){0,2}(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){2}|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){0,3}(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){0,4}(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::)((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3})|(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3})|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){0,5}(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3})|(((0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}):){0,6}(0|[1-9A-Fa-f][0-9A-Fa-f]{0,3}))?::)|(?!IPv6:)[0-9A-Za-z-]*[0-9A-Za-z]:[!-Z^-~]+)])"),
          Validators.maxLength(30)
        ]],
        password: [null, [
          Validators.required,
          Validators.minLength(10),
          Validators.maxLength(50)
        ]],
        confirmPassword: [null, [
          Validators.required
        ]]
      }, {
        validators: this.matchValue
      });
    }

    formHasError(error: string) {
      return !!this.registerForm.hasError(error);
    }

    isTouched(field: string) {
      return this.registerForm.get(field)?.touched;
    }

    hasErrors(field: string) {
      return this.registerForm.get(field)?.errors;
    }

    hasError(field: string, error: string) {
      return this.registerForm.get(field)?.hasError(error);
    }

    matchValue: ValidatorFn = (fg: AbstractControl) => {

      const password = fg.get('password')!.value;
      const confirmPassword = fg.get('confirmPassword')!.value;

      //return null
      return password === confirmPassword ? null : { isMatching: true };
    }

    onSubmit() {
      let applicationUserCreate = new ApplicationUsercreate(
        this.registerForm.get("username")?.value,
        this.registerForm.get("password")?.value,
        this.registerForm.get("email")?.value,
        this.registerForm.get("fullname")?.value
      )

      this.accountService.register(applicationUserCreate).subscribe(() => {
        this.router.navigate(['/dashboard'])
      })
    }
}
